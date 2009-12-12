//
// Copyright (c) 2008, Kevin McIntire
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Sep 08  Kevin McIntire  Creation
//

**
** JsonParser parses JSON.
**
** See [docLib]`docLib::Json` for details.
**
internal class JsonParser
{
  new make(InStream in)
  {
    this.in = in
  }

  // FIXIT need one to parse to Obj as well, doing Map/List for now
  internal Obj parse()
  {
    consume
    skipWhitespace
    if (cur == JsonToken.arrayStart)
      return parseArray
    else
      return parseObj
  }

  private Str:Obj? parseObj()
  {
    pairs := Str:Obj?[:] { ordered = true }

    skipWhitespace

    expect(JsonToken.objectStart)

    while (true)
    {
      skipWhitespace
      if (maybe(JsonToken.objectEnd)) return pairs

      // FIXIT would like pair to be a 2-tuple
      // OR a map with atom/symbol keys!
      // FIXIT what about empty object?
      parsePair(pairs)
      if (!maybe(JsonToken.comma)) break
    }

    expect(JsonToken.objectEnd)

    return pairs
  }

  private Void parsePair(Str:Obj? obj)
  {
    skipWhitespace
    key := parseKey

    skipWhitespace

    expect(JsonToken.colon)
    skipWhitespace

    val := parseVal
    skipWhitespace

    obj[key] = val
  }

  private Str parseKey()
  {
    parseStr
  }

  private Obj? parseVal()
  {
    if (this.cur == JsonToken.quote) return parseStr
    else if (this.cur.isDigit || this.cur == '-') return parseNum
    else if (this.cur == JsonToken.objectStart) return parseObj
    else if (this.cur == JsonToken.arrayStart) return parseArray
    else if (this.cur == 't')
    {
      "true".size.times |Int i|{ consume }
      return true
    }
    else if (this.cur == 'f')
    {
      "false".size.times |Int i|{ consume }
      return false
    }
    else if (this.cur == 'n')
    {
      "null".size.times |Int i|{ consume }
      return null
    }

    throw Err("Finish this method!")
  }

  // parse number, duration(FIXIT, or range)
  private Obj parseNum()
  {
    integral := StrBuf()
    fractional := StrBuf()
    exponent := StrBuf()
    if (maybe('-'))
      integral.add("-")

    while (this.cur.isDigit)
    {
      integral.addChar(this.cur)
      consume
    }

    if (this.cur == '.')
    {
      decimal := true
      consume
      while (this.cur.isDigit)
      {
        fractional.addChar(this.cur)
        consume
      }
    }

    if (this.cur == 'e' || this.cur == 'E')
    {
      exponent.addChar(this.cur)
      consume
      if (this.cur == '+') consume
      else if (this.cur == '-')
      {
        exponent.addChar(this.cur)
        consume
      }
      while (this.cur.isDigit)
      {
        exponent.addChar(this.cur)
        consume
      }
    }

    Num? num := null
    if (fractional.size > 0)
      num = Float.fromStr(integral.toStr+"."+fractional.toStr+exponent.toStr)
    else if (exponent.size > 0)
      num = Float.fromStr(integral.toStr+exponent.toStr)
    else num = Int.fromStr(integral.toStr)

    return num
  }

  private Str parseStr()
  {
    s := StrBuf()
    expect(JsonToken.quote)
    while( cur != JsonToken.quote )
    {
      if (cur == '\\')
      {
        s.addChar(escape)
      }
      else
      {
        s.addChar(cur)
        consume
      }
    }
    expect(JsonToken.quote)
    return s.toStr
  }

  private Int escape()
  {
    // consume slash
    expect('\\')

    // check basics
    switch (cur)
    {
      case 'b':   consume; return '\b'
      case 'f':   consume; return '\f'
      case 'n':   consume; return '\n'
      case 'r':   consume; return '\r'
      case 't':   consume; return '\t'
      case '"':   consume; return '"'
      case '\\':  consume; return '\\'
      case '/':   consume; return '/'
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
      return ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0)
    }

    throw err("Invalid escape sequence")
  }

  private List parseArray()
  {
    array := [,]
    expect(JsonToken.arrayStart)
    skipWhitespace
    if (maybe(JsonToken.arrayEnd)) return array

    while (true)
    {
      skipWhitespace
      val := parseVal
      array.add(val)
      if (!maybe(JsonToken.comma)) break
    }
    skipWhitespace
    expect(JsonToken.arrayEnd)
    return array
  }

  private Void skipWhitespace()
  {
    while (this.cur.isSpace)
      consume
  }

  private Void expect(Int tt)
  {
    if (this.cur != tt) throw err("Expected ${tt.toChar}, got ${cur.toChar} at ${pos}")
    consume
  }

  private Bool maybe(Int tt)
  {
    if (this.cur != tt) return false
    consume
    return true
  }

  private Void consume()
  {
    this.prev = this.cur
    this.cur = this.in.readChar ?: -1
    this.peek = this.in.peek ?: -1
    pos++
  }

  private Void rewind()
  {
    this.peek = this.cur
    this.cur = this.prev
    pos--
  }

  private Err err(Str msg) { ParseErr(msg) }

  private InStream in
  private Int cur := '?'
  private Int peek := '?'
  private Int prev := '?'
  private Int pos := 0
}