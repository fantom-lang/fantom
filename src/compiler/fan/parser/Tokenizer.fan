//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Sep 05  Brian Frank  Creation
//   18 May 06  Brian Frank  Ported from Java to Fan
//

**
** Tokenizer inputs a Str and output a list of Tokens
**
class Tokenizer : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with characters of source file.  The buffer
  ** passed must be normalized in that all newlines must be
  ** represented strictly as \n and not \r or \r\n (see
  ** File.readAllStr).  If isDoc is false, we skip all star-star
  ** Fandoc comments.
  **
  new make(Compiler compiler, Location location, Str buf, Bool isDoc)
    : super(compiler)
  {
    this.buf      = buf
    this.filename = location.file
    this.isDoc    = isDoc
    this.tokens   = TokenVal[,]
    this.inStrLiteral = false
    this.posOfLine = 0
    this.whitespace = false

    // initialize cur and peek
    cur = peek = ' '
    if (buf.size > 0) cur  = buf[0]
    if (buf.size > 1) peek = buf[1]
    pos = 0

    // if first line starts with #, then treat it like an end of
    // line, so that Unix guys can specify the executable to run
    if (cur === '#')
    {
      while (true)
      {
        if (cur === '\n') { consume; break }
        if (cur === 0) break
        consume
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Tokenize the entire input into a list of tokens.
  **
  TokenVal[] tokenize()
  {
    while (true)
    {
      tok := next
      tokens.add(tok)
      if (tok.kind === Token.eof) break
    }
    return tokens
  }

  **
  ** Return the next token in the buffer.
  **
  private TokenVal? next()
  {
    while (true)
    {
      // save current line
      line := this.line
      col  := this.col

      // find next token
      TokenVal tok := find
      if (tok == null) continue

      // fill in token's location
      tok.file = filename
      tok.line = line
      tok.col  = col
      tok.newline = lastLine < line
      tok.whitespace = whitespace

      // save last line, clear whitespace flag
      lastLine = line
      whitespace = false

      return tok
    }
    return null // TODO - shouldn't need this
  }

  **
  ** Find the next token or return null.
  **
  private TokenVal? find()
  {
    // skip whitespace
    if (cur.isSpace) { consume; whitespace = true; return null }

    // raw string literal r"c:\dir\foo.txt"
    if (cur === 'r' && peek === '"' && !inStrLiteral) return rawStr

    // alpha means keyword or identifier
    if (cur.isAlpha || cur === '_') return word

    // number or .number (note that + and - are handled as unary operator)
    if (cur.isDigit) return number
    if (cur === '.' && peek.isDigit) return number

    // str literal
    if (cur === '"')  return str
    if (cur === '`')  return uri
    if (cur === '\'') return ch

    // comments
    if (cur === '*' && peek === '*') return docComment
    if (cur === '/' && peek === '/') return skipCommentSL
    if (cur === '/' && peek === '*') return skipCommentML

    // symbols
    return symbol
  }

//////////////////////////////////////////////////////////////////////////
// Word
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a word token: alpha (alpha|number)*
  ** Words are either keywords or identifiers
  **
  private TokenVal word()
  {
    // store starting position of word
    start := pos

    // find end of word to compute length
    while (cur.isAlphaNum || cur === '_') consume

    // create Str (gc note this string might now reference buf)
    word := buf[start...pos]

    // check keywords
    keyword := Token.keywords[word]
    if (keyword != null)
      return TokenVal(keyword)

    // otherwise this is a normal identifier
    return TokenVal(Token.identifier, word)
  }

//////////////////////////////////////////////////////////////////////////
// Number
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a number literal token: int, float, decimal, or duration.
  **
  private TokenVal number()
  {
    // check for hex value
    if (cur === '0' && peek === 'x')
      return hex

    // find end of literal
    start := pos
    dot   := false
    exp   := false

    // whole part
    while (cur.isDigit || cur === '_') consume

    // fraction part
    if (cur === '.' && peek.isDigit)
    {
      dot = true
      consume
      while (cur.isDigit || cur === '_') consume
    }

    // exponent
    if (cur === 'e' || cur === 'E')
    {
      consume
      exp = true
      if (cur === '-' || cur === '+') consume
      if (!cur.isDigit) throw err("Expected exponent digits")
      while (cur.isDigit || cur === '_') consume
    }

    // string value of literal
    str := buf[start...pos].replace("_", "")

    // check for suffixes
    floatSuffix   := false
    decimalSuffix := false
    Int? dur      := null
    if (cur.isLower && peek.isLower)
    {
      if (cur === 'n' && peek === 's') { consume; consume; dur = 1 }
      if (cur === 'm' && peek === 's') { consume; consume; dur = 1000000 }
      if (cur === 's' && peek === 'e') { consume; consume; if (cur !== 'c') throw err("Expected 'sec' in Duration literal"); consume; dur = 1_000_000_000 }
      if (cur === 'm' && peek === 'i') { consume; consume; if (cur !== 'n') throw err("Expected 'min' in Duration literal"); consume; dur = 60_000_000_000 }
      if (cur === 'h' && peek === 'r') { consume; consume; dur = 3_600_000_000_000 }
      if (cur === 'd' && peek === 'a') { consume; consume; if (cur !== 'y') throw err("Expected 'day' in Duration literal"); consume; dur = 86_400_000_000_000 }
    }
    else if (cur === 'f' || cur === 'F')
    {
      consume
      floatSuffix = true
    }
    else if (cur === 'd' || cur === 'D')
    {
      consume
      decimalSuffix = true
    }

    try
    {
      // float literal
      if (floatSuffix)
      {
        num := Float.fromStr(str)
        return TokenVal(Token.floatLiteral, num)
      }

      // decimal literal
      if (decimalSuffix || dot || exp)
      {
        num := Decimal.fromStr(str)
        if (dur != null)
          return TokenVal(Token.durationLiteral, Duration((num*dur.toDecimal).toInt))
        else
          return TokenVal(Token.decimalLiteral, num)
      }

      // int literal
      num := Int.fromStr(str)
      if (dur != null)
        return TokenVal(Token.durationLiteral, Duration(num*dur))
      else
        return TokenVal(Token.intLiteral, num)
    }
    catch (ParseErr e)
    {
      throw err("Invalid numeric literal '$str'")
    }
  }

  **
  ** Process hex int/long literal starting with 0x
  **
  TokenVal hex()
  {
    consume // 0
    consume // x

    // read first hex
    Int val := cur.fromDigit(16)
    if (val == null) throw err("Expecting hex number")
    consume
    Int nibCount := 1
    while (true)
    {
      Int nib := cur.fromDigit(16)
      if (nib == null)
      {
        if (cur === '_') { consume; continue }
        break
      }
      nibCount++
      if (nibCount > 16) throw err("Hex literal too big")
      val = (val << 4) + nib;
      consume
    }

    return TokenVal(Token.intLiteral, val)
  }

//////////////////////////////////////////////////////////////////////////
// String
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a raw string literal token.
  **
  private TokenVal rawStr()
  {
    // consume opening 'r' and quote
    consume
    consume

    openLine := posOfLine
    openPos  := pos
    multiLineOk := true

    // string contents
    s := StrBuf()
    while (cur !==  '"')
    {
      if (cur <= 0) throw err("Unexpected end of string")

      if (cur === '\n')
      {
        s.addChar(cur)
        consume
        if (multiLineOk) multiLineOk = skipStrWs(openLine, openPos)
        continue
      }

      s.addChar(cur)
      consume
    }

    // close quote
    consume

    return TokenVal(Token.strLiteral, s.toStr)
  }

  **
  ** Parse a string literal token.
  **
  private TokenVal? str()
  {
    inStrLiteral = true
    try
    {
      // consume opening quote
      consume
      openLine := posOfLine
      openPos  := pos
      multiLineOk := true

      // store starting position
      s := StrBuf()

      // loop until we find end of string
      interpolated := false
      while (true)
      {
        if (cur === '"') { consume; break }
        if (cur === 0) throw err("Unexpected end of string")

        if (cur === '\n')
        {
          s.addChar(cur)
          consume
          if (multiLineOk) multiLineOk = skipStrWs(openLine, openPos)
          continue
        }

        if (cur === '$')
        {
          // if we have detected an interpolated string, then
          // insert opening paren to treat whole string atomically
          if (!interpolated)
          {
            interpolated = true
            tokens.add(makeVirtualToken(Token.lparen))
          }

          // process interpolated string, it returns null
          // if at end of string literal
          if (!strInterpolation(s.toStr))
          {
            tokens.add(makeVirtualToken(Token.rparen))
            return null
          }

          s.clear
        }
        else if (cur === '\\')
        {
          s.add(escape.toChar)
        }
        else
        {
          s.addChar(cur)
          consume
        }
      }

      // if interpolated then we add rparen to treat whole atomically
      if (interpolated)
      {
        tokens.add(makeVirtualToken(Token.strLiteral, s.toStr))
        tokens.add(makeVirtualToken(Token.rparen))
        return null
      }
      else
      {
        return TokenVal(Token.strLiteral, s.toStr)
      }
    }
    finally
    {
      inStrLiteral = false
    }
  }

  **
  ** Leading white space in a multi-line string is assumed
  ** to be outside of the string literal.  If there is an
  ** non-whitespace char, then it is an compile time error.
  ** Return true if ok, false on error.
  **
  private Bool skipStrWs(Int openLine, Int openPos)
  {
    for (i:=openLine; i<openPos; ++i)
    {
      a := buf[i]
      if ((a === '\t' && cur !== '\t') || (a !== '\t' && cur !== ' '))
      {
        if (cur == '\n') return true
        numTabs := 0; numSpaces := 0
        for (j:=openLine; j<openPos; ++j)
          { if (buf[j] == '\t') ++numTabs; else ++numSpaces }
        if (numTabs == 0)
          err("Leading space in multi-line Str must be $numSpaces spaces")
        else
          err("Leading space in multi-line Str must be $numTabs tabs and $numSpaces spaces")
        return false
      }
      consume
    }
    return true
  }

  **
  ** When we hit a $ inside a string it indicates an embedded
  ** expression.  We make this look like a stream of tokens
  ** such that:
  **   "a ${b} c" -> "a " + b + " c"
  ** Return true if more in the string literal.
  **
  private Bool strInterpolation(Str s)
  {
    consume // $
    tokens.add(makeVirtualToken(Token.strLiteral, s))
    tokens.add(makeVirtualToken(Token.plus))

    // if { we allow an expression b/w {...}
    if (cur === '{')
    {
      tokens.add(makeVirtualToken(Token.lparen))
      consume
      while (true)
      {
        if (cur === '"' || cur === 0) throw err("Unexpected end of string, missing }")
        tok := next
        if (tok.kind == Token.rbrace) break
        tokens.add(tok)
      }
      tokens.add(makeVirtualToken(Token.rparen))
    }

    // else also allow a single identifier with
    // dotted accessors x, x.y, x.y.z
    else
    {
      tok := next
      if (tok.kind !== Token.identifier &&
          tok.kind !== Token.thisKeyword &&
          tok.kind !== Token.superKeyword)
        throw err("Expected identifier after \$")
      tokens.add(tok)
      while (true)
      {
        if (cur !== '.') break
        tokens.add(next) // dot
        tok = next
        if (tok.kind !== Token.identifier) throw err("Expected identifier")
        tokens.add(tok)
      }
    }

    // if at end of string, all done
    if (cur === '\"')
    {
      consume
      return false
    }

    // add plus and return true to keep chugging
    tokens.add(makeVirtualToken(Token.plus))
    return true
  }

  **
  ** Create a virtual token for string interpolation.
  **
  private TokenVal makeVirtualToken(Token kind, Obj? value := null)
  {
    tok := TokenVal(kind, value)
    tok.file  = filename
    tok.line  = line
    tok.col   = col
    return tok
  }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a uri literal token.
  **
  private TokenVal uri()
  {
    // consume opening backtick
    consume

    // store starting position
    s := StrBuf()

    // loop until we find end of string
    while (true)
    {
      ch := cur
      if (ch === '`') { consume; break }
      if (ch === 0 || ch === '\n') throw err("Unexpected end of uri")
      if (ch === '$') throw err("Uri interpolation not supported yet")
      if (ch === '\\')
      {
        switch (peek)
        {
          case ':': case '/': case '?': case '#':
          case '[': case ']': case '@': case '\\':
          case '&': case '=': case ';':
            s.addChar(ch)
            s.addChar(peek)
            consume
            consume
          default:
            s.addChar(escape)
        }
      }
      else
      {
        consume
        s.addChar(ch)
      }
    }

    return TokenVal(Token.uriLiteral, s.toStr)
  }

//////////////////////////////////////////////////////////////////////////
// Char
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a char literal token.
  **
  private TokenVal ch()
  {
    // consume opening quote
    consume

    // if \ then process as escape
    c := -1
    if (cur === '\\')
    {
      c = escape
    }
    else
    {
      c = cur
      consume
    }

    // expecting ' quote
    if (cur !== '\'') throw err("Expecting ' close of char literal")
    consume

    return TokenVal(Token.intLiteral, c)
  }

  **
  ** Parse an escapse sequence which starts with a \
  **
  Int escape()
  {
    // consume slash
    if (cur !== '\\') throw err("Internal error")
    consume

    // check basics
    switch (cur)
    {
      case 'b':   consume; return '\b'
      case 'f':   consume; return '\f'
      case 'n':   consume; return '\n'
      case 'r':   consume; return '\r'
      case 't':   consume; return '\t'
      case '"':   consume; return '"'
      case '$':   consume; return '$'
      case '\'':  consume; return '\''
      case '`':   consume; return '`'
      case '\\':  consume; return '\\'
    }

    // check for uxxxx
    if (cur === 'u')
    {
      consume
      n3 := cur.fromDigit(16); consume
      n2 := cur.fromDigit(16); consume
      n1 := cur.fromDigit(16); consume
      n0 := cur.fromDigit(16); consume
      if (n3 == null || n2 == null || n1 == null || n0 == null) throw err("Invalid hex value for \\uxxxx")
      return ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0)
    }

    throw err("Invalid escape sequence")
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  **
  ** Skip a single line // comment
  **
  private TokenVal? skipCommentSL()
  {
    consume  // first slash
    consume  // next slash
    while (true)
    {
      if (cur === '\n') { consume; break }
      if (cur === 0) break
      consume
    }
    return null
  }

  **
  ** Skip a multi line /* comment.  Note unlike C/Java,
  ** slash/star comments can be nested.
  **
  private TokenVal? skipCommentML()
  {
    consume   // first slash
    consume   // next slash
    depth := 1
    while (true)
    {
      if (cur === '*' && peek === '/') { consume; consume; depth--; if (depth <= 0) break }
      if (cur === '/' && peek === '*') { consume; consume; depth++; continue }
      if (cur === 0) break
      consume
    }
    return null
  }

  **
  ** Parse a Javadoc style comment into a documentation comment token.
  **
  private TokenVal? docComment()
  {
    // if doc is off, then just skip the line and be done
    if (!isDoc) { skipCommentSL; return null }

    while (cur === '*') consume
    if (cur === ' ') consume

    // parse comment
    lines := Str[,]
    s := StrBuf()
    while (cur > 0)
    {
      // add to buffer and advance
      c := cur
      consume

      // if not at newline, then loop
      if (c !== '\n')
      {
        s.addChar(c)
        continue
      }

      // add line and reset buffer (but don't add leading empty lines)
      line := s.toStr
      if (!lines.isEmpty || !line.trim.isEmpty) lines.add(line)
      s.clear

      // we at a newline, check for leading whitespace(0+)/star(2+)/whitespace(1)
      while (cur === ' ' || cur === '\t') consume
      if (cur !== '*' || peek !== '*') break
      while (cur === '*') consume
      if (cur === ' ' || cur === '\t') consume
    }
    lines.add(s.toStr)

    // strip trailing empty lines
    while (!lines.isEmpty)
      if (lines.last.trim.isEmpty) lines.removeAt(-1)
      else break

    return TokenVal(Token.docComment, lines)
  }

//////////////////////////////////////////////////////////////////////////
// Symbol
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a symbol token (typically into an operator).
  **
  private TokenVal symbol()
  {
    c := cur
    consume
    switch (c)
    {
      case '\r':
        throw err("Carriage return \\r not allowed in source")
      case '!':
        if (cur === '=')
        {
          consume
          if (cur === '=') { consume; return TokenVal(Token.notSame) }
          return TokenVal(Token.notEq)
        }
        return TokenVal(Token.bang)
      case '#':
        return TokenVal(Token.pound)
      case '%':
        if (cur === '=') { consume; return TokenVal(Token.assignPercent) }
        return TokenVal(Token.percent)
      case '&':
        if (cur === '=') { consume; return TokenVal(Token.assignAmp) }
        if (cur === '&') { consume; return TokenVal(Token.doubleAmp) }
        return TokenVal(Token.amp)
      case '(':
        return TokenVal(Token.lparen)
      case ')':
        return TokenVal(Token.rparen)
      case '*':
        if (cur === '=') { consume; return TokenVal(Token.assignStar) }
        return TokenVal(Token.star)
      case '+':
        if (cur === '=') { consume; return TokenVal(Token.assignPlus) }
        if (cur === '+') { consume; return TokenVal(Token.increment) }
        return TokenVal(Token.plus)
      case ',':
        return TokenVal(Token.comma)
      case '-':
        if (cur === '>') { consume; return TokenVal(Token.arrow) }
        if (cur === '-') { consume; return TokenVal(Token.decrement) }
        if (cur === '=') { consume; return TokenVal(Token.assignMinus) }
        return TokenVal(Token.minus)
      case '.':
        if (cur === '.')
        {
          consume
          if (cur === '.') { consume; return TokenVal(Token.dotDotDot) }
          return TokenVal(Token.dotDot)
        }
        return TokenVal(Token.dot)
      case '/':
        if (cur === '=') { consume; return TokenVal(Token.assignSlash) }
        return TokenVal(Token.slash)
      case ':':
        if (cur === ':') { consume; return TokenVal(Token.doubleColon) }
        if (cur === '=') { consume; return TokenVal(Token.defAssign) }
        return TokenVal(Token.colon)
      case ';':
        return TokenVal(Token.semicolon)
      case '<':
        if (cur === '=')
        {
          consume
          if (cur === '>') { consume; return TokenVal(Token.cmp) }
          return TokenVal(Token.ltEq)
        }
        if (cur === '<')
        {
          consume
          if (cur === '=') { consume; return TokenVal(Token.assignLshift) }
          return TokenVal(Token.lshift)
        }
        return TokenVal(Token.lt)
      case '=':
        if (cur === '=')
        {
          consume
          if (cur === '=') { consume; return TokenVal(Token.same) }
          return TokenVal(Token.eq)
        }
        return TokenVal(Token.assign)
      case '>':
        if (cur === '=') { consume; return TokenVal(Token.gtEq) }
        if (cur === '>')
        {
          consume
          if (cur === '=') { consume; return TokenVal(Token.assignRshift) }
          return TokenVal(Token.rshift)
        }
        return TokenVal(Token.gt)
      case '?':
        if (cur === ':') { consume; return TokenVal(Token.elvis) }
        if (cur === '.') { consume; return TokenVal(Token.safeDot) }
        if (cur === '-')
        {
          consume
          if (cur !== '>') throw err("Expected '?->' symbol")
          consume
          return TokenVal(Token.safeArrow)
        }
        return TokenVal(Token.question)
      case '@':
        return TokenVal(Token.at)
      case '[':
        return TokenVal(Token.lbracket)
      case ']':
        return TokenVal(Token.rbracket)
      case '^':
        if (cur === '=') { consume; return TokenVal(Token.assignCaret) }
        return TokenVal(Token.caret)
      case '{':
        return TokenVal(Token.lbrace)
      case '|':
        if (cur === '|') { consume; return TokenVal(Token.doublePipe) }
        if (cur === '=') { consume; return TokenVal(Token.assignPipe) }
        return TokenVal(Token.pipe)
      case '}':
        return TokenVal(Token.rbrace)
      case '~':
        return TokenVal(Token.tilde)
    }

    if (c === 0)
      return TokenVal(Token.eof)

    throw err("Unexpected symbol: " + c.toChar + " (0x" + c.toHex + ")")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a CompilerException for current location in source.
  **
  override CompilerErr err(Str msg, Location? loc := null)
  {
    if (loc == null) loc = Location(filename, line, col)
    return super.err(msg, loc);
  }

////////////////////////////////////////////////////////////////
// Consume
////////////////////////////////////////////////////////////////

  **
  ** Consume the cur char and advance to next char in buffer:
  **  - updates cur and peek fields
  **  - updates the line and col count
  **  - end of file, sets fields to 0
  **
  private Void consume()
  {
    // if cur is a line break, then advance line number,
    // because the char we are getting ready to make cur
    // is the first char on the next line
    if (cur === '\n')
    {
      line++
      col = 1
      posOfLine = pos+1
    }
    else
    {
      col++
    }

    // get the next character from the buffer, any
    // problems mean that we have read past the end
    cur = peek
    pos++
    if (pos+1 < buf.size)
      peek = buf[pos+1] // next peek is cur+1
    else
      peek = 0
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  /*
  static Void main()
  {
    t1 := Duration.now
    files := File(`/dev/fan/src/testSys/fan/`).list
    files.each |File f|
    {
      tok := Tokenizer(null, Location(f.name), f.readAllStr, false).tokenize
      echo("-- " + f + " [" + tok.size + "]")
    }
    t2 := Duration.now
    echo("Time: " + (t2-t1).toMillis)
    echo("Time: " + (t2-t1))
  }
  */

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str buf           // buffer
  private Int pos           // index into buf for cur
  private Bool isDoc        // return documentation comments or if false ignore them
  private Str filename      // source file name
  private Int line := 1     // pos line number
  private Int col := 1      // pos column number
  private Int cur           // current char
  private Int peek          // next char
  private Int lastLine      // line number of last token returned from next()
  private Int posOfLine     // index into buf for start of current line
  private TokenVal[] tokens // token accumulator
  private Bool inStrLiteral // return if inside a string literal token
  private Bool whitespace   // was there whitespace before current token


}