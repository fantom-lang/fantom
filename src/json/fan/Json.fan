//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Kevin McIntire  Creation
//

**
** Json implements serialization and deserialization of Fan
** objects to and from Javascript Object Notation (JSON).
**
** See [docLib]`docLib::Json` for details.
** See [docCookbook]`docCookbook::Json` for coding examples.
**
class Json
{
  // FIXIT only map entry point currently, need Obj/slots
  public static Void write(Str:Obj map, StrBuf buf)
  {
    writeMap(map, buf)
  }

  // FIXIT need instream entry point
  public static Str:Obj read(StrBuf buf)
  {
    json := JsonParser.make(buf.toStr)
    return json.parse
  }

  private static Void writeMap(Str:Obj map, StrBuf buf)
  {
    buf.add(JsonToken.OBJECT_START.toChar)
    notFirst := false
    map.each |Obj val, Str key|
    {
      if (notFirst) buf.add(JsonToken.COMMA.toChar)
      writePair(key, val, buf)
      notFirst = true
    }
    buf.add(JsonToken.OBJECT_END.toChar)
  }

  private static Void writePair(Str key, Obj val, StrBuf buf)
  {
      writeKey(key, buf)
      buf.add(JsonToken.COLON.toChar)
      writeValue(val, buf)
  }

  private static Void writeKey(Str key, StrBuf buf)
  {
    writeString(key, buf)
  }

  // FIXIT actually need to write values out for number, obj, array, true, 
  // false, null
  private static Void writeValue(Obj val, StrBuf buf)
  {
    if (val is Str) writeString(val as Str, buf)
    else if (val is Num) writeNumber(val as Num, buf)
    else if (val is List) writeArray(val as List, buf)
    else if (val is Bool) writeBoolean(val as Bool, buf)
    else if (val == null) writeNull(buf)
    else writeMap(val, buf) // FIXIT stick with map for now
  }

  private static Void writeArray(Obj[] array, StrBuf buf)
  {
    buf.add(JsonToken.ARRAY_START.toChar)
    notFirst := false
    array.each |Obj o|
    {
      if (notFirst) buf.add(JsonToken.COMMA.toChar)
      writeValue(o, buf)
      notFirst = true
    }
    buf.add(JsonToken.ARRAY_END.toChar)
  }

  private static Void writeString(Str str, StrBuf buf)
  {
    buf.add(JsonToken.QUOTE.toChar)
    buf.add(str)
    buf.add(JsonToken.QUOTE.toChar)
  }

  private static Void writeNumber(Num num, StrBuf buf)
  {
    buf.add(num)
  }

  private static Void writeBoolean(Bool bool, StrBuf buf)
  {
    buf.add(bool)
  }

  private static Void writeNull(StrBuf buf)
  {
    buf.add("null")
  }

}