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
** See [docCookbook]`docCookbook::Json` for coding examples.
**
internal class JsonParser
{
  new make(InStream buf)
  {
    this.buf = buf
  }

  // FIXIT need one to parse to Obj as well, doing Map for now
  internal Str:Obj parse()
  {
    consume
    return parseObject
  }

  private Str:Obj parseObject()
  {
    pairs := Str:Obj[:]

    skipWhitespace

    expect(JsonToken.objectStart)

    while (true)
    {
      skipWhitespace
      if (maybe(JsonToken.objectEnd)) return pairs

      // FIXIT would like pair to be a 2-tuple
      // OR a map with atom/symbol keys!
      // FIXIT what about empty object?
      pair := parsePair
      pairs.add(pair[keyAtom], pair[valueAtom])
      if (!maybe(JsonToken.comma)) break
    }

    expect(JsonToken.objectEnd)

    return pairs
  }

  private Str:Obj parsePair()
  {
    map := Str:Obj[:]

    skipWhitespace
    key := key

    skipWhitespace

    expect(JsonToken.colon)
    skipWhitespace

    val := value
    skipWhitespace

    map.add(keyAtom, key)
    map.add(valueAtom, val)

    return map
  }

  private Str key()
  {
    return string
  }

  private Obj value()
  {
    if (this.cur == JsonToken.quote) return string
    else if (this.cur.isDigit || this.cur == '-') return number
    else if (this.cur == JsonToken.objectStart) return parseObject
    else if (this.cur == JsonToken.arrayStart) return array
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

  private Num number()
  {
    integral := StrBuf.make
    fractional := StrBuf.make
    exponent := StrBuf.make
    if (maybe('-'))
      integral.add("-")

    while (this.cur.isDigit)
    {
      integral.add(this.cur.toChar)
      consume
    }

    if (this.cur == '.')
    {
      decimal := true
      consume
      while (this.cur.isDigit)
      {
        fractional.add(this.cur.toChar)
	consume
      }
    }
    if (this.cur == 'e' || this.cur == 'E')
    {
      exponent.add(this.cur.toChar)
      consume
      if (this.cur == '+') consume
      else if (this.cur == '-')
      {
	exponent.add(this.cur.toChar)
        consume
      }
      while (this.cur.isDigit)
      {
        exponent.add(this.cur.toChar)
	consume
      }
    }
    if (fractional.size > 0)
      return Decimal.fromStr(integral.toStr+"."+fractional.toStr+exponent.toStr)
    else if (exponent.size > 0)
      return Decimal.fromStr(integral.toStr+exponent.toStr)
    return Int.fromStr(integral.toStr)
  }

  private Str string()
  {
    s := StrBuf.make
    expect(JsonToken.quote)
    while (this.cur != JsonToken.quote && this.prev != '\\')
    {
      s.add(this.cur.toChar)
      consume
    }
    expect(JsonToken.quote)
    return s.toStr
  }

  private List array()
  {
    array := [,]
    expect(JsonToken.arrayStart)
    skipWhitespace
    if (maybe(JsonToken.arrayEnd)) return array

    while (true)
    {
      skipWhitespace
      val := value
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
    if (this.cur != tt) throw Err("Expected "+tt.toChar+", got "+
                                   this.cur.toChar)
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
    this.cur = this.buf.read
    this.peek = this.buf.peek
  }

  private Void rewind()
  {
    this.peek = this.cur
    this.cur = this.prev
  }

  private InStream buf
  private Int cur := '?'
  private Int peek := '?'
  private Int prev := '?'
  private Int pos := 0
  private static const Str keyAtom := "key_atom"
  private static const Str valueAtom := "value_atom"
}
