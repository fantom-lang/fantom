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
  // FIXIT only map entry point currently, need Obj/slots
  *** Write the given object as JSON to the given stream.
  public static Void write(Obj obj, OutStream out)
  {
    JsonWriter.write(obj, out)
    out.flush
  }

  // FIXIT need instream entry point
  public static Str:Obj? read(InStream buf)
  {
    json := JsonParser.make(buf)
    return json.parse
  }
}