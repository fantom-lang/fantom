//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//   30 Aug 11  Brian Frank  Refactor out of fluxText
//

**
** SyntaxParser parses text into a SyntaxDoc
**
internal class SyntaxParser
{

  new make(SyntaxRules rules)
  {
    this.rules = rules
    this.tokenizer = LineTokenizer(rules)
  }

  SyntaxDoc parse(InStream in)
  {
    doc := SyntaxDoc(rules)
    SyntaxLine? tail := null
    num := 1
    while (true)
    {
      // read next line of text
      text := in.readLine
      if (text == null) break

      // parse into SyntaxLine
      line := parseLine(num++, text)

      // append to line linked list
      if (tail == null) doc.lines = line
      else tail.next = line
      tail = line
    }
    return doc
  }

  private SyntaxLine parseLine(Int num, Str lineText)
  {
    line := SyntaxLine(num)
    try
    {
      // normalize tabs
      if (tabsToSpaces != 0)
        lineText = convertTabsToSpaces(lineText, tabsToSpaces)

      // tokenize segments
      tokenizer.tokenizeLine(lineText) |type, text|
      {
        line.segments.add(type).add(text)
      }
    }
    catch (Err e)
    {
      e.trace
      line.segments = [SyntaxType.text, lineText]
    }
    return line
  }

  private static Str convertTabsToSpaces(Str text, Int ts)
  {
    if (!text.contains("\t")) return text
    s := StrBuf()
    text.each |ch|
    {
      if (ch == '\t')
        s.add(Str.spaces(ts - (s.size%ts)))
      else
        s.addChar(ch)
    }
    return s.toStr
  }

  ** Number of spaces to convert a tab character to or zero
  ** to disable tab to space conversion
  Int tabsToSpaces := 2

  private SyntaxRules rules        // syntax rules for current document
  private LineTokenizer tokenizer  // line tokenizer for rules
}

**************************************************************************
** LineTokenizer
**************************************************************************

internal class LineTokenizer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(SyntaxRules rules)
  {
    this.rules = rules
    this.brackets = rules.brackets

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

    // str literals
    strs = StrMatch[,]
    if (rules.strs != null)
      rules.strs.each |SyntaxStr s| { strs.add(toStrMatch(s)) }
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizing
//////////////////////////////////////////////////////////////////////////

  ** Tokenize to given callback
  Void tokenizeLine(Str line, |SyntaxType, Str| f)
  {
    // reset line
    this.line = line
    this.lineSize = line.size
    this.pos  = 0
    if (lineSize > 0) this.cur  = line[0]
    if (lineSize > 1) this.peek = line[1]

    // iterate until we hit end of line
    textStart := 0
    while (cur != 0)
    {
      // parse next token
      thisStart := pos
      type := next

      // if this is text, keep chugging until we
      // get to next special token or end of line
      if (type == SyntaxType.text) continue

      // iterate last text chunk
      if (textStart < thisStart)
        f(SyntaxType.text, line[textStart..<thisStart])

      // iterate this token
      f(type, line[thisStart..<pos])

      // reset textStart
      textStart = pos
    }

    // iterate last text chunk
    if (textStart < line.size)
      f(SyntaxType.text, line[textStart..<line.size])
  }

  private SyntaxType next()
  {
    // if inside multi-line string literal
    if (inStr != null) return strLiteral(inStr)

    // if inside block comment or comment open
    if (inComment > 0 || commentStart.isMatch) return blockComment

    // check for end-of-line comments
    for (i:=0; i<comments.size; ++i)
    {
      if (comments[i].isMatch)
      {
        cur = 0
        pos = line.size // force end of line
        return SyntaxType.comment
      }
    }

    // identifier which might be keyword
    if (keywordPrefixes[cur.shiftl(16).or(peek)] &&
        (pos==0 || !line[pos-1].isAlphaNum))
    {
      start := pos
      consume
      consume
      while (cur.isAlphaNum || cur == '_') consume
      word := line[start..<pos]
      if (keywords[word]) return SyntaxType.keyword
      return SyntaxType.text
    }

    // check for str literals
    for (i:=0; i<strs.size; ++i)
      if (strs[i].start.isMatch) return strLiteral(strs[i])

    // brackets
    if (brackets.containsChar(cur))
    {
      consume
      return SyntaxType.bracket
    }

    // other chars
    consume
    return SyntaxType.text
  }

  private SyntaxType blockComment()
  {
    while (cur != 0)
    {
      if (commentStart.isMatch)
      {
        commentStart.consume
        ++inComment
        if (!rules.blockCommentsNest) inComment = 1
      }

      if (commentEnd.isMatch)
      {
        commentEnd.consume
        --inComment
      }

      if (inComment <= 0) break
      consume
    }
    return SyntaxType.comment
  }

  private SyntaxType strLiteral(StrMatch s)
  {
    if (inStr !== s) s.start.consume
    while (cur != 0)
    {
      if (s.end.isMatch && countEscapes(s.escape).isEven)
      {
        s.end.consume
        inStr = null
        return SyntaxType.literal
      }
      consume
    }
    if (s.multiLine) inStr = s
    return SyntaxType.literal
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
      for (i:=2; i<chars.size; ++i) if (chars[i] != line[pos+i]) return false
      return true
    }
    catch (Err e)
    {
      return false
    }
  }

  ** Count the number of escape chars preceeding the current char.
  private Int countEscapes(Int esc)
  {
    n := 0
    while (line[pos-n-1] == esc) n++
    return n
  }

//////////////////////////////////////////////////////////////////////////
// Consume
//////////////////////////////////////////////////////////////////////////

  private Void consume()
  {
    cur = peek
    pos++
    if (pos >= lineSize) pos = lineSize
    if (pos+1 < line.size)
    {
      peek = line[pos+1] // next peek is cur+1
    }
    else
    {
      peek = 0
    }
  }

  Void consumeN(Int n)
  {
    for (; n > 0; --n) consume
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // rule lookups
  private SyntaxRules rules        // syntax rules for tokenizing
  private Str brackets             // str of bracket symbols
  private Int:Bool keywordPrefixes // first two letter of keywords
  private Str:Bool keywords        // keywords
  private Matcher[] comments       // matchers for eol comments
  private Matcher commentStart     // matcher to check comment start
  private Matcher commentEnd       // matcher to check comment end
  private StrMatch[] strs          // matchers for str literals

  // multi-line blocks
  private Int inComment            // nested level of block comments
  private StrMatch? inStr          // in multi-line string literal

  // current line
  private Str? line                // line being parsed
  private Int lineSize             // total size of line
  private Int pos                  // index into line for cur
  private Int cur                  // current char
  private Int peek                 // next char
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

** StrMatch handles matching the start and end
** delimiter and managing multi-line string blocks
internal class StrMatch
{
  Matcher? start
  Matcher? end
  Int escape
  Bool multiLine
}

