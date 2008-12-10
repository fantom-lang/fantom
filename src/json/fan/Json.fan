//
// Copyright (c) 2008, Kevin McIntire
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
**
class Json
{
  ***
  *** Write the given object as JSON to the given stream.
  *** Currently only Maps are supported fully.
  *** 
  public static Void write(Obj obj, OutStream out)
  {
    JsonWriter.write(obj, out)
    out.flush
  }

  ***
  *** Read JSON from the given stream to a Map.
  *** Currently only reads to a Map; eventually
  *** we will incorporate type inforamation to
  *** return a Obj.
  ***
  public static Str:Obj? read(InStream buf)
  {
    json := JsonParser.make(buf)
    return json.parse
  }
}