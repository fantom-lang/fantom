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
  internal static Void write(OutStream out, Obj obj)
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
    writeValue(out, obj)
  }

  private static Void writeObj(OutStream out, Obj obj)
  {
    type := obj.type

    out.print(JsonToken.objectStart.toChar)
    writePair(out, "fanType", type.signature)
    if (type.facet("simple", null, true))
    {
      out.print(",")
      writePair(out, "fanValue", obj.toStr)
    }
    else
    {
      type.fields.each |Field f|
      {
        out.print(",")
        key := f.name
        // skip static and all that stuff in objencoder
        val := f.get(obj)
        writePair(out, f.name, val)
      }
    }
    out.print(JsonToken.objectEnd.toChar)
  }

  private static Void writeMap(OutStream out, Str:Obj map)
  {
    out.print(JsonToken.objectStart.toChar)

    // FIXIT do we want a type??

    notFirst := false
    map.each |Obj? val, Str key|
    {
      if (notFirst) out.print(JsonToken.comma.toChar)
      writePair(out, key, val)
      notFirst = true
    }
    out.print(JsonToken.objectEnd.toChar)
  }

  // FIXIT actually need to write values out for number, obj, array, true,
  // false, null
  private static Void writeValue(OutStream out, Obj? val)
  {
    // FIXIT need route for DateTime
    if (val is Str) writeString(out, val as Str)
    else if (val is Duration) writeDuration(out, val as Duration)
    else if (val is Num) writeNumber(out, val as Num)
    else if (val is List) writeArray(out, val as List)
    else if (val is Bool) writeBoolean(out, val as Bool)
    else if (val == null) writeNull(out)
    else if (val is Map) writeMap(out, val)
    else if (val is Uri) writeUri(out, val as Uri)
    else writeObj(out, val)
  }

  private static Void writeArray(OutStream out, Obj[] array)
  {
    out.print(JsonToken.arrayStart.toChar)
    // FIXIT we cant really put a type in here, need to infer it

    notFirst := false
    array.each |Obj? o|
    {
      if (notFirst) out.print(JsonToken.comma.toChar)
      writeValue(out, o)
      notFirst = true
    }
    out.print(JsonToken.arrayEnd.toChar)
  }

  private static Void writePair(OutStream out, Str key, Obj? val)
  {
      writeKey(out, key)
      out.print(JsonToken.colon.toChar)
      writeValue(out, val)
  }

  private static Void writeKey(OutStream out, Str key)
  {
    writeString(out, key)
  }

  private static Void writeString(OutStream out, Str str)
  {
    out.print(JsonToken.quote.toChar)
    out.print(str)
    out.print(JsonToken.quote.toChar)
  }

  private static Void writeUri(OutStream out, Uri uri)
  {
    out.print(JsonToken.quote.toChar)
    out.print(JsonToken.grave.toChar)
    out.print(uri);
    out.print(JsonToken.grave.toChar)
    out.print(JsonToken.quote.toChar)
  }

  private static Void writeNumber(OutStream out, Num num)
  {
    out.print(num)
  }

  private static Void writeDuration(OutStream out, Duration dur)
  {
    out.print(JsonToken.quote.toChar)
    out.print(dur.toStr)
    out.print(JsonToken.quote.toChar)
  }

  private static Void writeBoolean(OutStream out, Bool bool)
  {
    out.print(bool)
  }

  private static Void writeNull(OutStream out)
  {
    out.print("null")
  }

}