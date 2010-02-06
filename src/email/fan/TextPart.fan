//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 08  Brian Frank  Creation
//

**
** TextPart is used to model email parts with a text MIME type.
** The default is "text/plain".
**
@Serializable
class TextPart : EmailPart
{

  **
  ** Text body of the email part.
  **
  Str text := ""

  **
  ** Construct with default type of "text/plain".
  **
  new make()
  {
    headers["Content-Type"] = "text/plain"
    headers["Content-Transfer-Encoding"] = "8bit"
  }

  **
  ** Validate this part - throw Err if not configured correctly:
  **   - text must be non-null
  **   - Content-Type must be defined
  **   - if Content-Type charset not defined, defaults to utf-8
  **   - Content-Transfer-Encoding must be 8bit unless using us-ascii
  **
  override Void validate()
  {
    super.validate

    // check text
    if ((Obj?)text == null) throw NullErr("text null in ${Type.of(this).name}")

    // check content-type header
    ct := headers["Content-Type"]
    if (ct == null) throw Err("Must define Content-Type header")

    // set charset to utf-8 if not explicit
    mime := MimeType.fromStr(ct)
    if (mime.params["charset"] == null)
      headers["Content-Type"] = mime.toStr + "; charset=utf-8"

    // require 8bit transfer unless us-ascii
    if (headers["Content-Transfer-Encoding"] != "8bit")
    {
      if (MimeType.fromStr(ct).params["charset"] != "us-ascii")
        throw Err("Content-Transfer-Encoding must be 8bit if not using charset=us-ascii")
    }
  }

  **
  ** Encode as a MIME message according to RFC 822.
  **
  override Void encode(OutStream out)
  {
    // ensure valid and configure defaults
    validate

    // get charset
    mime := MimeType.fromStr(headers["Content-Type"])
    charset := Charset.fromStr(mime.params["charset"])

    // write headers
    super.encode(out)

    // write text lines
    out.charset = charset
    in := text.in
    in.eachLine |Str line|
    {
      if (line == ".") line = ". "
      out.print(line).print("\r\n")
    }
    out.charset = Charset.utf8
    out.print("\r\n")
  }

}