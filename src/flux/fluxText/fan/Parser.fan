//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//

using fwt

**
** Parser is responsible for tokenizing a document line
** into syntax color coding.
**
internal class Parser
{
//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with source line.
  **
  new make(Doc doc)
  {
    options  = doc.options
    syntax   = doc.syntax
    rules    = doc.rules
    brackets = rules.brackets

    // build keyword map, and also a prefix map
    // of the first two characters for fast yes/no
    keywords = Str :Bool[:] { def=false }
    keywordPrefixes = Int:Bool[:] { def=false }
    if (rules.keywords != null)
    {
      rules.keywords.each |Str k|
      {
        keywords[k] = true
        keywordPrefixes[k[0].shiftl(16).or(k[1])] = true
      }
    }

    // single line comments
    comments= Matcher[,]
    rules.comments?.each |Str s| { comments.add(toMatcher(s)) }

    // block comments
    commentStart = toMatcher(rules.blockCommentStart)
    commentEnd   = toMatcher(rules.blockCommentEnd)
    commentOpen  = BlockOpen(this, rules.blockCommentStart, [0, syntax.comment].ro)

    // str literals
    strs = StrMatch[,]
    if (rules.strs != null)
      rules.strs.each |SyntaxStr s| { strs.add(toStrMatch(s)) }
  }

//////////////////////////////////////////////////////////////////////////
// Tokenize
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the specified line text into a new Line instance.
  ** If close is non-null, then we are reparsing the line with
  ** the knowledge that the start of the line is inside a
  ** multi-line block.
  **
  Line parseLine(Str text, BlockClose? close := null)
  {
    try
    {
      if (options.convertTabsToSpaces)
        text = convertTabsToSpaces(text, options.tabSpacing)

      init(text)

      styling := Obj[,]
      if (close != null)
      {
        styling.addAll(close.stylingOverride)
        consumeN(close.pos)
      }

      parseStyling(styling)

      if (!needFatLine) return Line { it.text = text; it.styling = styling }
      return FatLine
      {
        it.text = text
        it.styling = styling
        it.commentNesting = this.commentNesting
        it.opens = this.opens
        it.closeBlocks = this.closes
      }
    }
    catch (Err e)
    {
      e.trace
      return Line { it.text = text; it.styling = [0, syntax.text] }
    }
  }

  internal static Str convertTabsToSpaces(Str text, Int ts)
  {
    if (!text.contains("\t")) return text
    s := StrBuf()
    text.each |Int ch, Int i|
    {
      if (ch == '\t')
        s.add(Str.spaces(ts - (s.size%ts)))
      else
        s.addChar(ch)
    }
    return s.toStr
  }

  private Void parseStyling(Obj[] styling)
  {
    while (cur != 0)
    {
      p := pos
      tok := next
      switch (tok)
      {
        case Token.bracket: addStyle(styling, p, syntax.bracket)
        case Token.keyword: addStyle(styling, p, syntax.keyword)
        case Token.literal: addStyle(styling, p, syntax.literal)
        case Token.comment: addStyle(styling, p, syntax.comment)
        default:            addStyle(styling, p, syntax.text)
      }
    }
  }

  private Void addStyle(Obj[] styling, Int pos, RichTextStyle style)
  {
    if (styling.last === style) return
    styling.add(pos).add(style)
  }

  private Bool needFatLine()
  {
    return commentNesting != 0 || opens != null || closes != null
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the next token.
  **
  private Token next()
  {
    // check for end-of-line comments
    for (i:=0; i<comments.size; ++i)
    {
      if (comments[i].isMatch)
      {
        cur = 0
        return Token.comment
      }
    }

    // check for block comments
    if (commentStart.isMatch) return blockComment
    if (commentEnd.isMatch)   return blockComment

    // check for str literals
    for (i:=0; i<strs.size; ++i)
      if (strs[i].start.isMatch) return strLiteral(strs[i])

    // brackets
    if (brackets.containsChar(cur))
    {
      consume
      return Token.bracket
    }

    // number
    /*
    if (cur === '-' && peek.isDigit) consume
    if (cur.isDigit) return number
    */

    // identifier which might be keyword
    if (keywordPrefixes[cur.shiftl(16).or(peek)])
    {
      start := pos
      consume
      consume
      while (cur.isAlphaNum || cur == '_') consume
      word := text[start..<pos]
      if (keywords[word]) return Token.keyword
      return Token.text
    }

    // tokenize an identifier in one big swoop
    if (cur.isAlpha)
    {
      while (cur.isAlphaNum || cur == '_') consume
      return Token.text
    }

    // consume symbols one at a time
    consume
    return Token.text
  }

  **
  ** Parse number literal:
  **   123
  **   2.6f
  **   2.6e-5f
  **   0xab_12
  **   2.5sec
  **
  private Token number()
  {
    while (true)
    {
      if (cur.isAlphaNum ||  cur == '_') { consume; continue }
      if (cur == '.' && peek.isDigit) { consume; continue }
      if (peek == '-' && (cur == 'e' || cur == 'E')) { consume; consume; continue }
      break
    }
    return Token.literal
  }

  **
  ** Parse str literal
  **
  private Token strLiteral(StrMatch s)
  {
    s.start.consume
    while (cur != 0)
    {
      if (s.end.isMatch && countEscapes(s.escape).isEven)
      {
        s.end.consume
        return Token.literal
      }
      consume
    }
    if (s.multiLine) opens = s.blockOpen
    return Token.literal
  }

  **
  ** Count the number of escape chars preceeding the current char.
  **
  private Int countEscapes(Int esc)
  {
    n := 0
    while (text[pos-n-1] == esc) n++
    return n
  }

  **
  ** Block comment to end token or end of line,
  ** keep track of nesting.
  **
  Token blockComment()
  {
    thisNesting := 0
    while (cur != 0)
    {
      if (commentStart.isMatch)
      {
        commentStart.consume
        commentNesting++
        thisNesting++
      }

      if (commentEnd.isMatch)
      {
        commentEnd.consume
        commentNesting--
        thisNesting--
      }

      if (thisNesting <= 0) return Token.comment
      consume
    }
    opens = commentOpen
    return Token.comment
  }

//////////////////////////////////////////////////////////////////////////
// Matching Functions
//////////////////////////////////////////////////////////////////////////

  StrMatch toStrMatch(SyntaxStr s)
  {
    return StrMatch
    {
      start     = toMatcher(s.delimiter, s.escape)
      end       = toMatcher(s.delimiterEnd ?: s.delimiter, s.escape)
      escape    = s.escape
      multiLine = s.multiLine
      blockOpen = BlockOpen(this, s.delimiter, [0, syntax.literal].ro)
    }
  }

  Matcher toMatcher(Str? tok, Int esc := 0)
  {
    tok = tok?.trim ?: ""
    switch (tok.size)
    {
      case 0:
        return Matcher(0, |->Bool| { noMatch }, |->| {})
      case 1:
        if (esc > 0)
          return Matcher(1, |->Bool| { match1Esc(tok[0], esc) }, |->| { consume })
        else
          return Matcher(1, |->Bool| { match1(tok[0]) }, |->| { consume })
      case 2:
        if (esc > 0)
          return Matcher(2, |->Bool| { match2Esc(tok[0], tok[1], esc) }, |->| { consume; consume })
        else
          return Matcher(2, |->Bool| { match2(tok[0], tok[1]) }, |->| { consume; consume })
      default:
        return Matcher(tok.size, |->Bool| { matchN(tok) }, |->| { consumeN(tok.size) })
    }
  }

  Bool noMatch() { return false }

  Bool match1(Int ch1) { return cur == ch1 }

  Bool match2(Int ch1, Int ch2) { return cur == ch1 && peek == ch2 }

  Bool match1Esc(Int ch1, Int esc) { return cur == ch1 && countEscapes(esc).isEven }

  Bool match2Esc(Int ch1, Int ch2, Int esc) { return cur == ch1 && peek == ch2 && countEscapes(esc).isEven }

  Bool matchN(Str chars) // assume no escape for 3 or more
  {
    try
    {
      if (cur != chars[0] || peek != chars[1]) return false
      for (i:=2; i<chars.size; ++i) if (chars[i] != text[pos+i]) return false
      return true
    }
    catch (Err e)
    {
      return false
    }
  }

////////////////////////////////////////////////////////////////
// Consume
////////////////////////////////////////////////////////////////

  **
  ** Initialize state to parse specified line.
  **
  private Void init(Str text)
  {
    this.text = text
    cur = peek = ' '
    if (text.size > 0) cur  = text[0]
    if (text.size > 1) peek = text[1]
    pos = commentNesting = 0
    opens = null
    closes = null
    checkCloses
  }

  **
  ** Consume the cur char and advance to next char
  ** in buffer and update cur/peek fields.
  **
  private Void consume()
  {
    cur = peek
    pos++
    if (pos+1 < text.size)
      peek = text[pos+1] // next peek is cur+1
    else
      peek = 0
    checkCloses
  }

  **
  ** Consume n characters
  **
  Void consumeN(Int n)
  {
    n.times { consume }
  }
  **
  ** Consume remaining characters
  **
  Void consumeRest()
  {
    consumeN(text.size-pos)
  }

  **
  ** Check if the current token is a match for closing
  ** multi-line blocks.  If so add it to our closes list
  **
  private Void checkCloses()
  {
    strs.each |StrMatch m|
    {
      if (m.multiLine && m.end.isMatch)
      {
        if (closes == null) closes = Block[,]
        closes.add(BlockClose(m.blockOpen, pos+m.end.size))
      }
    }

    if (commentEnd.isMatch)
    {
      if (closes == null) closes = Block[,]
      closes.add(BlockClose(commentOpen, pos+commentEnd.size))
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal TextEditorOptions options // configured options
  internal SyntaxOptions syntax    // configured options
  internal SyntaxRules rules       // syntax rules for current document

  private Str brackets             // str of bracket symbols
  private Int:Bool keywordPrefixes // first two letter of keywords
  private Str:Bool keywords        // keywords
  private Matcher[] comments       // matchers for eol comments
  private Matcher commentStart     // matcher to check comment start
  private Matcher commentEnd       // matcher to check comment end
  private BlockOpen commentOpen    // open handle for block comments
  private StrMatch[] strs          // matchers for str literals

  private Str text := ""           // line being parsed
  private Int pos                  // index into text for cur
  private Int cur                  // current char
  private Int peek                 // next char

  private Int commentNesting       // levels of block comments opened/closed
  private Block? opens             // if current line opens block
  private Block[]? closes          // if current line closes block
}


**************************************************************************
** Token
**************************************************************************

** Token represents a string of color coded chars
internal enum class Token
{
  text,
  bracket,
  keyword,
  literal,
  preprocessor,
  comment
}

**************************************************************************
** Matcher
**************************************************************************

** Matcher is used to match a specific token
** against the current character
internal class Matcher
{
  new make(Int sz, |->Bool| m, |->| c) { size = sz; matchFunc = m; consumeFunc = c }
  Bool isMatch() { return matchFunc.call }
  Void consume() { consumeFunc.call }
  |->Bool| matchFunc
  |->| consumeFunc
  const Int size
}

**************************************************************************
** StrMatch
**************************************************************************

** StrMatch handles matching the start and end
** delimiter and managing multi-line string blocks
internal class StrMatch
{
  Matcher? start
  Matcher? end
  Int escape
  Bool multiLine
  BlockOpen? blockOpen
}

**************************************************************************
** BlockOpen
**************************************************************************

** BlockOpen implements the Block interface when we detect
** that a block comment or multi-line string is opened.  BlockOpens
** are reused by the entire parser (see commentOpen and StrMatch).
** They are paired with BlockCloses.
internal class BlockOpen : Block
{
  new make(Parser p, Str? n, Obj[] s) { parser = p; name = n; stylingOverride = s }

  override Line? closes(Line line, Block open) { throw Err("illegal state") }

  override Str toStr() { return name }

  override Obj[]? stylingOverride
  readonly Parser parser
  const Str? name
}

**************************************************************************
** BlockClose
**************************************************************************

** BlockClose instances are used whenever we detect a potential
** closing token for a block comment or multi-line string.  Each
** instance is allocated per line to cache the re-parse.  But we
** pair with the open block to efficiently manage memory.
internal class BlockClose : Block
{
  new make(BlockOpen open, Int pos) { this.open = open; this.pos = pos }

  override Obj[]? stylingOverride() { return open.stylingOverride }

  override Line? closes(Line line, Block open)
  {
    if (open !== this.open) return null
    if (cachedLineOnClose == null)
      cachedLineOnClose = ((BlockOpen)open).parser.parseLine(line.text, this)
     return cachedLineOnClose
  }

  override Str toStr() { return "$open.name:$pos" }

  readonly BlockOpen open
  const Int pos
  Line? cachedLineOnClose
}