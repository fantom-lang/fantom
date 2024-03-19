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
@Js
class JsonOutStream : OutStream
{

  **
  ** Convenience for `writeJson` to an in-memory string.
  **
  public static Str writeJsonToStr(Obj? obj)
  {
    buf := StrBuf()
    JsonOutStream(buf.out).writeJson(obj)
    return buf.toStr
  }

  **
  ** Convenience for pretty-printing JSON to an in-memory string.
  **
  public static Str prettyPrintToStr(Obj? obj)
  {
    buf := StrBuf()
    JsonOutStream(buf.out) { it.prettyPrint = true }.writeJson(obj)
    return buf.toStr
  }

  **
  ** Construct by wrapping given output stream.
  **
  new make(OutStream out) : super(out) {}

  **
  ** Flag to escape characters over 0x7f using '\uXXXX'
  **
  Bool escapeUnicode := true

  **
  ** Write JSON in pretty-printed format. This format produces more readable
  ** JSON at the expense of larger output size.
  **
  Bool prettyPrint := false

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
         if (obj is Str)   writeJsonStr(obj)
    else if (obj is Map)   writeJsonMap(obj)
    else if (obj is List)  writeJsonList(obj)
    else if (obj is Float) writeJsonFloat(obj)
    else if (obj is Num)   writeJsonNum(obj)
    else if (obj is Bool)  writeJsonBool(obj)
    else if (obj == null)  writeJsonNull
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
    first := true
    type.fields.each |f, i|
    {
      if (f.isStatic || f.hasFacet(Transient#) == true) return
      if (first) first = false
      else writeChar(JsonToken.comma)
      writeJsonPair(f.name, f.get(obj))
    }
    writeChar(JsonToken.objectEnd)
  }

  private Void writeJsonMap(Map map)
  {
    writeChar(JsonToken.objectStart).ppnl.indent
    notFirst := false
    map.each |val, key|
    {
      if (key isnot Str) throw Err("JSON map key is not Str type: $key [$key.typeof]")
      if (notFirst) writeChar(JsonToken.comma).ppnl
      writeJsonPair(key, val)
      notFirst = true
    }
    ppnl.unindent
    ppsp.writeChar(JsonToken.objectEnd)
  }

  private Void writeJsonList(Obj?[] array)
  {
    writeChar(JsonToken.arrayStart).ppnl.indent
    notFirst := false
    array.each |item|
    {
      if (notFirst) writeChar(JsonToken.comma).ppnl
      ppsp.writeJson(item)
      notFirst = true
    }
    ppnl.unindent
    ppsp.writeChar(JsonToken.arrayEnd)
  }

  private Void writeJsonStr(Str str)
  {
    writeChar(JsonToken.quote)
    str.each |char|
    {
      if (char <= 0x7f || !escapeUnicode)
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

  private Void writeJsonFloat(Float float)
  {
    // check for unsupported literals
    if (float.isNaN || float == Float.posInf || float == Float.negInf)
      throw IOErr("Unsupported JSON float literal: '${float}'")

    print(float)
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
    ppsp.writeJsonStr(key)
    writeChar(JsonToken.colon); if (prettyPrint) writeChar(' ')
    writeJson(val)
  }

//////////////////////////////////////////////////////////////////////////
// Pretty-Printing Support
//////////////////////////////////////////////////////////////////////////

  ** Write a newline if we are pretty-printing
  private This ppnl()
  {
    if (prettyPrint) writeChar('\n')
    return this
  }

  ** Write leading-space if we are pretty-printing
  private This ppsp()
  {
    if (prettyPrint) print(Str.spaces(level * 2))
    return this
  }

  private This indent() { ++level; return this }

  private This unindent() { --level; return this }

  ** Indentation level when pretty-printing
  private Int level := 0
}