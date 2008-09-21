//
// Copyright (c) 2008, Brian Frank and Andy Frank
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
  new make(Str buf)
  {
    this.buf = buf
  }

  // FIXIT need one to parse to Obj as well, doing Map for now
  internal Str:Obj parse()
  {
    return parseObject
  }

  private Str:Obj parseObject()
  {
    pairs := Str:Obj[:]

    skipWhitespace
    expect(JsonToken.OBJECT_START)

    while (true)
    {
      // FIXIT would like pair to be a 2-tuple
      // OR a map with atom/symbol keys!
      // FIXIT what about empty object?
      pair := parsePair
      pairs.add(pair[KEY_ATOM], pair[VALUE_ATOM])
      if (!maybe(JsonToken.COMMA)) break
    }

    expect(JsonToken.OBJECT_END)

    return pairs
  }

  private Str:Obj parsePair()
  {
    map := Str:Obj[:]
    skipWhitespace

    key := key
    skipWhitespace

    expect(JsonToken.COLON)
    skipWhitespace

    val := value
    skipWhitespace

    map.add(KEY_ATOM, key)
    map.add(VALUE_ATOM, val)

    return map
  }

  private Str key()
  {
    return string
  }

  private Obj value()
  {
    if (this.cur == JsonToken.QUOTE) return string
    else if (this.cur.isDigit || this.cur == '-') return number
    else if (this.cur == JsonToken.OBJECT_START) return parseObject
    else if (this.cur == JsonToken.ARRAY_START) return array
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

    consume
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
    rewind
    if (fractional.size > 0)
      return Decimal.fromStr(integral.toStr+"."+fractional.toStr+exponent.toStr)
    else if (exponent.size > 0)
      return Decimal.fromStr(integral.toStr+exponent.toStr)
    return Int.fromStr(integral.toStr)
  }

  private Str string()
  {
    s := StrBuf.make
    expect(JsonToken.QUOTE)
    consume
    while (this.cur != JsonToken.QUOTE && this.buf[this.pos-1] != '\\')
    {
      s.add(this.cur.toChar)
      consume
    }
    rewind
    expect(JsonToken.QUOTE)
    return s.toStr
  }

  private List array()
  {
    array := [,]
    expect(JsonToken.ARRAY_START)
    while (true)
    {
      skipWhitespace
      val := value
      array.add(val)
      if (!maybe(JsonToken.COMMA)) break
    }
    skipWhitespace
    expect(JsonToken.ARRAY_END)
    return array
  }

  private Void skipWhitespace()
  {
    consume
    while (this.cur.isSpace)
    {
      consume
    }
    rewind
  }

  private Void expect(Int tt)
  {
    consume
    if (this.cur != tt) throw Err("Expected "+tt.toChar+", got "+
                                   this.cur.toChar)
  }

  private Bool maybe(Int tt)
  {
    consume
    if (this.cur == tt) return true
    rewind
    return false
  }

  private Void consume()
  {
    this.cur = this.buf[this.pos++]
  }

  private Void rewind()
  {
    this.cur = this.buf[--this.pos]
  }

  private Str buf
  private Int cur := -1
  private Int pos := 0
  private static const Str KEY_ATOM := "key_atom"
  private static const Str VALUE_ATOM := "value_atom"
}
