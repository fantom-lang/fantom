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
** See [docCookbook]`docCookbook::Json` for coding examples.
**
class Json
{
  // FIXIT only map entry point currently, need Obj/slots
  public static Void write(Str:Obj map, StrBuf buf)
  {
    JsonWriter.writeMap(map, buf)
  }

  // FIXIT need instream entry point
  public static Str:Obj read(StrBuf buf)
  {
    json := JsonParser.make(buf.toStr)
    return json.parse
  }
}