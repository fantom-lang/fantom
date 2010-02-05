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
**
internal class JsonWriter
{
  internal new make(OutStream out)
  {
    this.out = out
  }

  internal Void write(Obj? obj)
  {
         if (obj is Str)  writeStr(obj)
    else if (obj is Num)  writeNum(obj)
    else if (obj is Bool) writeBool(obj)
    else if (obj is Map)  writeMap(obj)
    else if (obj is List) writeList(obj)
    else if (obj == null) writeNull
    else writeObj(obj)
  }

  private Void writeObj(Obj obj)
  {
    type := Type.of(obj)

    // if a simple, write it as a string
    ser := type.facet(Serializable#, false) as Serializable
    if (ser == null) throw IOErr("Object type not serializable: $type")

    if (ser.simple)
    {
      writeStr(obj.toStr)
      return
    }

    // serialize as JSON object
    this.out.writeChar(JsonToken.objectStart)
    type.fields.each |f, i|
    {
      if (i != 0) this.out.writeChar(JsonToken.comma).writeChar('\n')
      if (f.isStatic || f.hasFacet(Transient#) == true) return
      writePair(f.name, f.get(obj))
    }
    this.out.writeChar(JsonToken.objectEnd)
  }

  private Void writeMap(Str:Obj? map)
  {
    this.out.writeChar(JsonToken.objectStart)
    notFirst := false
    map.each |val, key|
    {
      if (notFirst) this.out.writeChar(JsonToken.comma).writeChar('\n')
      writePair(key, val)
      notFirst = true
    }
    this.out.writeChar(JsonToken.objectEnd)
  }

  private Void writeList(Obj?[] array)
  {
    this.out.writeChar(JsonToken.arrayStart)
    notFirst := false
    array.each |item|
    {
      if (notFirst) this.out.writeChar(JsonToken.comma)
      write(item)
      notFirst = true
    }
    this.out.writeChar(JsonToken.arrayEnd)
  }

  private Void writeStr(Str str)
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

  private Void writeNum(Num num)
  {
    this.out.print(num)
  }

  private Void writeBool(Bool bool)
  {
    this.out.print(bool)
  }

  private Void writeNull()
  {
    this.out.print("null")
  }

  private Void writePair(Str key, Obj? val)
  {
    writeStr(key)
    this.out.writeChar(JsonToken.colon)
    write(val)
  }

  private OutStream out
}