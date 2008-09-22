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
  internal static Void writeMap(Str:Obj map, OutStream buf)
  {
    buf.print(JsonToken.objectStart.toChar)
    notFirst := false
    map.each |Obj val, Str key|
    {
      if (notFirst) buf.print(JsonToken.comma.toChar)
      writePair(key, val, buf)
      notFirst = true
    }
    buf.print(JsonToken.objectEnd.toChar)
  }

  private static Void writePair(Str key, Obj val, OutStream buf)
  {
      writeKey(key, buf)
      buf.print(JsonToken.colon.toChar)
      writeValue(val, buf)
  }

  private static Void writeKey(Str key, OutStream buf)
  {
    writeString(key, buf)
  }

  // FIXIT actually need to write values out for number, obj, array, true, 
  // false, null
  private static Void writeValue(Obj val, OutStream buf)
  {
    if (val is Str) writeString(val as Str, buf)
    else if (val is Num) writeNumber(val as Num, buf)
    else if (val is List) writeArray(val as List, buf)
    else if (val is Bool) writeBoolean(val as Bool, buf)
    else if (val == null) writeNull(buf)
    else writeMap(val, buf) // FIXIT stick with map for now
  }

  private static Void writeArray(Obj[] array, OutStream buf)
  {
    buf.print(JsonToken.arrayStart.toChar)
    notFirst := false
    array.each |Obj o|
    {
      if (notFirst) buf.print(JsonToken.comma.toChar)
      writeValue(o, buf)
      notFirst = true
    }
    buf.print(JsonToken.arrayEnd.toChar)
  }

  private static Void writeString(Str str, OutStream buf)
  {
    buf.print(JsonToken.quote.toChar)
    buf.print(str)
    buf.print(JsonToken.quote.toChar)
  }

  private static Void writeNumber(Num num, OutStream buf)
  {
    buf.print(num)
  }

  private static Void writeBoolean(Bool bool, OutStream buf)
  {
    buf.print(bool)
  }

  private static Void writeNull(OutStream buf)
  {
    buf.print("null")
  }

}