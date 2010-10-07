//
// Copyright (c) 2008, Kevin McIntire
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Sep 08  Kevin McIntire  Creation
//   24 Mar 10  Brian Frank     json::JsonWriter to util::JsonOutStream
//

**
** JsonOutStream writes objects in Javascript Object Notation (JSON).
**
** See [pod doc]`pod-doc#json` for details.
**
class JsonOutStream : OutStream
{

  **
  ** Convenience for `writeJson` to an in-memory string.
  **
  public static Str writeJsonToStr(Obj? obj)
  {
    buf := Buf()  // TODO: switch to StrBuf once #1031 is fixed
    JsonOutStream(buf.out).writeJson(obj)
    return buf.flip.readAllStr
  }

  **
  ** Construct by wrapping given output stream.
  **
  new make(OutStream out) : super(out) {}

  **
  ** Write the given object as JSON to this stream.
  ** The obj must be one of the follow:
  **   - null
  **   - Bool
  **   - Num
  **   - Str
  **   - Str:Obj?
  **   - Obj?[]
  **   - [simple]`docLang::Serialization#simple` (written as JSON string)
  **   - [serializable]`docLang::Serialization#serializable` (written as JSON object)
  **
  This writeJson(Obj? obj)
  {
         if (obj is Str)  writeJsonStr(obj)
    else if (obj is Num)  writeJsonNum(obj)
    else if (obj is Bool) writeJsonBool(obj)
    else if (obj is Map)  writeJsonMap(obj)
    else if (obj is List) writeJsonList(obj)
    else if (obj == null) writeJsonNull
    else writeJsonObj(obj)
    return this
  }

  private Void writeJsonObj(Obj obj)
  {
    type := Type.of(obj)

    // if a simple, write it as a string
    ser := type.facet(Serializable#, false) as Serializable
    if (ser == null) throw IOErr("Object type not serializable: $type")

    if (ser.simple)
    {
      writeJsonStr(obj.toStr)
      return
    }

    // serialize as JSON object
    writeChar(JsonToken.objectStart)
    type.fields.each |f, i|
    {
      if (i != 0) writeChar(JsonToken.comma).writeChar('\n')
      if (f.isStatic || f.hasFacet(Transient#) == true) return
      writeJsonPair(f.name, f.get(obj))
    }
    writeChar(JsonToken.objectEnd)
  }

  private Void writeJsonMap(Str:Obj? map)
  {
    writeChar(JsonToken.objectStart)
    notFirst := false
    map.each |val, key|
    {
      if (notFirst) writeChar(JsonToken.comma).writeChar('\n')
      writeJsonPair(key, val)
      notFirst = true
    }
    writeChar(JsonToken.objectEnd)
  }

  private Void writeJsonList(Obj?[] array)
  {
    writeChar(JsonToken.arrayStart)
    notFirst := false
    array.each |item|
    {
      if (notFirst) writeChar(JsonToken.comma)
      writeJson(item)
      notFirst = true
    }
    writeChar(JsonToken.arrayEnd)
  }

  private Void writeJsonStr(Str str)
  {
    writeChar(JsonToken.quote)
    str.each |char|
    {
      if (char <= 0x7f)
      {
        switch (char)
        {
          case '\b': writeChar('\\').writeChar('b')
          case '\f': writeChar('\\').writeChar('f')
          case '\n': writeChar('\\').writeChar('n')
          case '\r': writeChar('\\').writeChar('r')
          case '\t': writeChar('\\').writeChar('t')
          case '\\': writeChar('\\').writeChar('\\')
          case '"':  writeChar('\\').writeChar('"')
          default: writeChar(char)
        }
      }
      else
      {
        writeChar('\\').writeChar('u').print(char.toHex(4))
      }
    }
    writeChar(JsonToken.quote)
  }

  private Void writeJsonNum(Num num)
  {
    print(num)
  }

  private Void writeJsonBool(Bool bool)
  {
    print(bool)
  }

  private Void writeJsonNull()
  {
    print("null")
  }

  private Void writeJsonPair(Str key, Obj? val)
  {
    writeJsonStr(key)
    writeChar(JsonToken.colon)
    writeJson(val)
  }
}