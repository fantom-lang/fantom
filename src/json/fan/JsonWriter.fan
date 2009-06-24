//
// Copyright (c) 2008, Kevin McIntire
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Sep 08  Kevin McIntire  Creation
//

**
** JsonWriter writes out JSON.
** objects to and from Javascript Object Notation (JSON).
**
** See [docLib]`docLib::Json` for details.
** See [docCookbook]`docCookbook::Json` for coding examples.
**
internal class JsonWriter
{
  internal new make(OutStream out)
  {
    this.out = out
  }

  internal Void write(Obj obj)
  {
    // Map is written with no top level type information;
    // pairs may have type info of course
    // FIXIT need to make mapping of types in fan to json
    // DateTime ?
    // Decimal, Float, Int -> number, done
    // Bool -> bool literal done
    // Duration - literal, forks off number
    // Enum?
    // List -> [] done
    // Map -> {} done
    // MimeType
    // Month
    // Range -> literal - not covered in seralization!
    // TimeZone
    // Uri -> literal, done
    // Version
    // Weekday
    writeValue(obj)
  }

  private Void writeObj(Obj obj)
  {
    type := obj.type

    this.out.writeChar(JsonToken.objectStart)
    writePair("fanType", type.signature)
    if (type.facet("simple", null, true))
    {
      this.out.print(",")
      writePair("fanValue", obj.toStr)
    }
    else
    {
      type.fields.each |Field f|
      {
        this.out.print(",")
        key := f.name
        // TODO: skip static and all that stuff in objencoder
        val := f.get(obj)
        writePair(f.name, val)
      }
    }
    this.out.writeChar(JsonToken.objectEnd)
  }

  private Void writeMap(Str:Obj map)
  {
    this.out.writeChar(JsonToken.objectStart)

    // FIXIT do we want a type??

    notFirst := false
    map.each |Obj? val, Str key|
    {
      if (notFirst) this.out.writeChar(JsonToken.comma).writeChar('\n')
      writePair(key, val)
      notFirst = true
    }
    this.out.writeChar(JsonToken.objectEnd)
  }

  // FIXIT actually need to write values out for number, obj, array, true,
  // false, null
  private Void writeValue(Obj? val)
  {
    // FIXIT need route for DateTime
    if (val is Str) writeString(val)
    else if (val is Duration) writeDuration(val)
    else if (val is Num) writeNumber(val)
    else if (val is List) writeArray(val)
    else if (val is Bool) writeBoolean(val)
    else if (val == null) writeNull
    else if (val is Map) writeMap(val)
    else if (val is Uri) writeUri(val)
    else writeObj(val)
  }

  private Void writeArray(Obj[] array)
  {
    this.out.writeChar(JsonToken.arrayStart)
    // FIXIT we cant really put a type in here, need to infer it

    notFirst := false
    array.each |Obj? o|
    {
      if (notFirst) this.out.writeChar(JsonToken.comma)
      writeValue(o)
      notFirst = true
    }
    this.out.writeChar(JsonToken.arrayEnd)
  }

  private Void writePair(Str key, Obj? val)
  {
    writeKey(key)
    this.out.writeChar(JsonToken.colon)
    writeValue(val)
  }

  private Void writeKey(Str key)
  {
    writeString(key)
  }

  private Void writeString(Str str)
  {
    this.out.writeChar(JsonToken.quote)
    str.each |char|
    {
      if (char <= 0x7f)
      {
        switch (char)
        {
          case '\b': this.out.writeChar('\\').writeChar('b')
          case '\f': this.out.writeChar('\\').writeChar('f')
          case '\n': this.out.writeChar('\\').writeChar('n')
          case '\r': this.out.writeChar('\\').writeChar('r')
          case '\t': this.out.writeChar('\\').writeChar('t')
          case '\\': this.out.writeChar('\\').writeChar('\\')
          case '"':  this.out.writeChar('\\').writeChar('"')
          default: this.out.writeChar(char)
        }
      }
      else
      {
        this.out.writeChar('\\').writeChar('u').print(char.toHex(4))
      }
    }
    this.out.writeChar(JsonToken.quote)
  }

  private Void writeUri(Uri uri)
  {
    this.out.writeChar(JsonToken.quote)
    this.out.print(uri)
    this.out.writeChar(JsonToken.quote)
  }

  private Void writeNumber(Num num)
  {
    this.out.print(num)
  }

  private Void writeDuration(Duration dur)
  {
    this.out.writeChar(JsonToken.quote)
    this.out.print(dur.toStr)
    this.out.writeChar(JsonToken.quote)
  }

  private Void writeBoolean(Bool bool)
  {
    this.out.print(bool)
  }

  private Void writeNull()
  {
    this.out.print("null")
  }

  private OutStream out
}