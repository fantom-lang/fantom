//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 May 11  Brian Frank  Creation
//

**
** Tokenizer for fanr query language.
** See `docFanr::Queries` for details and formal grammer.
**
internal class Tokenizer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Str input)
  {
    this.index = -1
    this.input = input
    this.tok   = Token.eof
    consume
    consume
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizing
//////////////////////////////////////////////////////////////////////////

  **
  ** Read the next token, store result in `tok` and `val`
  **
  Token next()
  {
    // reset
    val = null

    // skip whitespace or comments
    while (cur.isSpace) consume

    // handle various starting chars
    if (cur.isAlpha || cur == '*') return tok = word
    if (cur == '"' || cur == '\'')  return tok = str
    if (cur.isDigit) return tok = num

    // symbol
    return tok = symbol
  }

//////////////////////////////////////////////////////////////////////////
// Token Productions
//////////////////////////////////////////////////////////////////////////

  private Token word()
  {
    s := StrBuf()
    stars := 0
    while (cur.isAlphaNum || cur == '_' || cur == '*')
    {
      if (cur == '*') stars++
      s.addChar(cur)
      consume
    }
    id := s.toStr
    val = id

    if (stars > 0) return Token.idPattern
    return Token.id
  }

  private Token num()
  {
    // consume all the things that might be part of this number token
    s := StrBuf().addChar(cur);
    consume
    dashes := 0; dots := 0
    while ((cur.isDigit) ||
           (cur == '_')  ||
           (cur == '-' && dots == 0) ||
           (cur == '.' && dashes == 0))
    {
      if (cur == '-') dashes++
      if (cur == '.') dots++
      if (cur != '_') s.addChar(cur)
      consume
    }

    // check for Date
    if (dashes == 2)
    {
      val = Date.fromStr(s.toStr)
      return Token.date
    }

    // check for Version
    if (dots > 0)
    {
      val = Version.fromStr(s.toStr)
      return Token.version
    }

    // parse as Number
    val = Int.fromStr(s.toStr)
    return Token.int
  }

  private Token str()
  {
    quote := cur
    consume // opening quote
    s := StrBuf()
    while (true)
    {
      ch := cur
      if (ch == quote) { consume; break }
      if (ch == '$') throw err("String interpolation not supported")
      if (ch == 0) throw err("Unexpected end of str")
      if (ch == '\\') { s.addChar(escape); continue }
      consume
      s.addChar(ch)
    }
    val = s.toStr
    return Token.str
  }

  private Int escape()
  {
    // consume slash
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
    if (cur == 'u')
    {
      consume
      n3 := cur.fromDigit(16); consume
      n2 := cur.fromDigit(16); consume
      n1 := cur.fromDigit(16); consume
      n0 := cur.fromDigit(16); consume
      if (n3 == null || n2 == null || n1 == null || n0 == null) throw err("Invalid hex value for \\uxxxx")
      return n3.shiftl(12).or(n2.shiftl(8)).or(n1.shiftl(4)).or(n0)
    }

    throw err("Invalid escape sequence")
  }

  **
  ** Parse a symbol token (typically into an operator).
  **
  private Token symbol()
  {
    c := cur
    consume
    switch (c)
    {
      case 0: return Token.eof
      case '\r':
        throw err("Carriage return \\r not allowed in source")
      case ',':
        return Token.comma
      case '-':
        return Token.minus
      case '+':
        return Token.plus
      case '.':
        return Token.dot
      case '<':
        if (cur == '=')
        {
          consume
          return Token.ltEq
        }
        return Token.lt
      case '=':
        if (cur == '=') { consume; return Token.eq }
      case '>':
        if (cur == '=') { consume; return Token.gtEq }
        return Token.gt
      case '!':
        if (cur == '=') { consume; return Token.notEq }
      case '~':
        if (cur == '=') { consume; return Token.like }
    }

    if (c == 0) return Token.eof

    throw err("Unexpected symbol: " + c.toChar + " (0x" + c.toHex + ")")
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  ParseErr err(Str msg) { ParseErr("$msg: $input") }

//////////////////////////////////////////////////////////////////////////
// Char Reads
//////////////////////////////////////////////////////////////////////////

  private Void consume()
  {
    cur  = peek
    peek = ++index < input.size ? input[index] : 0
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Token tok          // current token type
  Obj? val           // token literal or identifier
  private Str input  // query being parsed
  private Int index  // index into str of cur
  private Int cur    // current char
  private Int peek   // next char
}

**************************************************************************
** Token
**************************************************************************

internal enum class Token
{

  // identifer/literals
  id        ("identifier"),
  idPattern ("identifier pattern"),
  int       ("Int"),
  date      ("Date"),
  version   ("Version"),
  str       ("Str"),
  dot       ("."),
  comma     (","),
  minus     ("-"),
  plus      ("+"),
  eq        ("==", QueryOp.eq),
  notEq     ("==", QueryOp.notEq),
  like      ("~=", QueryOp.like),
  lt        ("<",  QueryOp.lt),
  ltEq      ("<=", QueryOp.ltEq),
  gt        (">",  QueryOp.gt),
  gtEq      (">=", QueryOp.gtEq),
  eof       ("eof");

  private new make(Str s, QueryOp? q := null) { symbol = s; queryOp = q}
  override Str toStr() { symbol }
  Bool isScalar() { this === int || this === str || this === date || this === version }
  const Str symbol
  const QueryOp? queryOp
}