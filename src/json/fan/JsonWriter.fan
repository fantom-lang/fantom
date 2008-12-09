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
  internal static Void write(Obj obj, OutStream buf)
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
    if (obj is Map) writeMap(obj as Map, buf)
    else writeObj(obj, buf)
  }

  private static Void writeObj(Obj obj, OutStream buf)
  {
    type := obj.type

    buf.print(JsonToken.objectStart.toChar)
    writePair("fanType", type.signature, buf)
    if (type.facet("simple", null, true))
    {
      buf.print(",")
      writePair("fanValue", obj.toStr, buf)
    }
    else
    {
      type.fields.each |Field f|
      {
        buf.print(",")
        key := f.name
        // skip static and all that stuff in objencoder
        val := f.get(obj)
        writePair(f.name, val, buf)
      }
    }
    buf.print(JsonToken.objectEnd.toChar)
  }

  private static Void writeMap(Str:Obj map, OutStream buf)
  {
    buf.print(JsonToken.objectStart.toChar)

    // FIXIT do we want a type??

    notFirst := false
    map.each |Obj? val, Str key|
    {
      if (notFirst) buf.print(JsonToken.comma.toChar)
      writePair(key, val, buf)
      notFirst = true
    }
    buf.print(JsonToken.objectEnd.toChar)
  }

  // FIXIT actually need to write values out for number, obj, array, true,
  // false, null
  private static Void writeValue(Obj? val, OutStream buf)
  {
    // FIXIT need route for DateTime
    if (val is Str) writeString(val as Str, buf)
    else if (val is Duration) writeDuration(val as Duration, buf)
    else if (val is Num) writeNumber(val as Num, buf)
    else if (val is List) writeArray(val as List, buf)
    else if (val is Bool) writeBoolean(val as Bool, buf)
    else if (val == null) writeNull(buf)
    else if (val is Map) writeMap(val, buf)
    else if (val is Uri) writeUri(val as Uri, buf)
    else writeObj(val, buf)
  }

  private static Void writeArray(Obj[] array, OutStream buf)
  {
    buf.print(JsonToken.arrayStart.toChar)
    // FIXIT we cant really put a type in here, need to infer it

    notFirst := false
    array.each |Obj? o|
    {
      if (notFirst) buf.print(JsonToken.comma.toChar)
      writeValue(o, buf)
      notFirst = true
    }
    buf.print(JsonToken.arrayEnd.toChar)
  }

  private static Void writePair(Str key, Obj? val, OutStream buf)
  {
      writeKey(key, buf)
      buf.print(JsonToken.colon.toChar)
      writeValue(val, buf)
  }

  private static Void writeKey(Str key, OutStream buf)
  {
    writeString(key, buf)
  }

  private static Void writeString(Str str, OutStream buf)
  {
    buf.print(JsonToken.quote.toChar)
    buf.print(str)
    buf.print(JsonToken.quote.toChar)
  }

  private static Void writeUri(Uri uri, OutStream buf)
  {
    buf.print(JsonToken.quote.toChar)
    buf.print(JsonToken.grave.toChar)
    buf.print(uri);
    buf.print(JsonToken.grave.toChar)
    buf.print(JsonToken.quote.toChar)
  }

  private static Void writeNumber(Num num, OutStream buf)
  {
    buf.print(num)
  }

  private static Void writeDuration(Duration dur, OutStream buf)
  {
    buf.print(dur.toStr)
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