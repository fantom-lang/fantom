//
// Copyright (c) 2008, Kevin McIntire
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Kevin McIntire  Creation
//

**
** Serialization to/from Javascript Object Notation (JSON).
**
@Deprecated { msg = "Use new 'util' APIs" }
class Json
{
  **
  ** Write the given object as JSON to the given stream.
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
  public static Void write(OutStream out, Obj? obj)
  {
    JsonWriter(out).write(obj)
    out.flush
  }

  **
  ** Convenience for `write` to an in-memory string.
  **
  public static Str writeToStr(Obj? obj)
  {
    buf := StrBuf()
    JsonWriter(buf.out).write(obj)
    return buf.toStr
  }

  **
  ** Read a JSON object from the given stream and return
  ** one of the follow types:
  **   - null
  **   - Bool
  **   - Int
  **   - Float
  **   - Str
  **   - Str:Obj?
  **   - Obj?[]
  **
  ** See [Str.in]`sys::Str.in` to read from an in-memory string.
  **
  public static Obj? read(InStream in)
  {
    return JsonParser(in).parse
  }
}