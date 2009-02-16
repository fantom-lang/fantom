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
  **
  ** Write the given object as JSON to the given stream.
  ** The object passed must be with a 'Str:Obj?' map or
  ** a 'Obj?[]' list.
  **
  public static Void write(OutStream out, Obj obj)
  {
    JsonWriter.write(out, obj)
    out.flush
  }

  **
  ** Read a JSON object from the given stream and return
  ** either a 'Str:Obj?' map or a 'Obj?[]' list.
  **
  public static Obj read(InStream in)
  {
    return JsonParser(in).parse
  }
}