//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 08  Brian Frank  Creation
//

**
** FilePart is used to transfer binary content from a File.
**
class FilePart : EmailPart
{

  **
  ** File content
  **
  File? file

  **
  ** Construct with default type of "text/plain".
  **
  new make()
  {
    headers["Content-Transfer-Encoding"] = "base64"
  }

  **
  ** Validate this part - throw Err if not configured correctly:
  **   - file must be non-null
  **   - if Content-Type not set, defaults to file.mimeType
  **   - if Content-Type name param not set, defaults to file.name
  **   - Content-Transfer-Encoding must be base64
  **
  override Void validate()
  {
    super.validate

    // check file is configured
    if ((Obj?)file == null) throw Err("file null in ${Type.of(this).name}")

    // default content-type to file mime type
    if (headers["Content-Type"] == null)
      headers["Content-Type"] = file.mimeType.toStr

    // add name parameter
    mime := MimeType.fromStr(headers["Content-Type"])
    if (mime.params["name"] == null && file.name.isAscii)
      headers["Content-Type"] = mime.toStr + "; name=\"$file.name\""

    // we only support base64
    if (headers["Content-Transfer-Encoding"] != "base64")
      throw Err("Content-Transfer-Encoding must be base64")
  }

  **
  ** Encode as a MIME message according to RFC 822.
  **
  override Void encode(OutStream out)
  {
    // ensure valid and configure defaults
    validate

    // write headers
    super.encode(out)

    // write file contents in base64
    buf := Buf() { capacity = 100 }
    in := file.in
    try
    {
      left := file.size
      while (left > 0)
      {
        in.readBufFully(buf, left.min(48))
        out.print(buf.toBase64).print("\r\n")
        left -= buf.size
        buf.clear
      }
    }
    finally
    {
      in.close
    }
  }

}