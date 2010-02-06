//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 08  Brian Frank  Creation
//

**
** MultiPart is used to model a multipart MIME type.  The
** default is "multipart/mixed".
**
@Serializable
class MultiPart : EmailPart
{

  **
  ** The sub-parts of this multipart.
  **
  EmailPart[] parts := EmailPart[,]

  **
  ** Construct with default type of "multipart/mixed".
  **
  new make()
  {
    headers["Content-Type"] = "multipart/mixed"
  }

  **
  ** Validate this part - throw Err if not configured correctly:
  **   - must have at least one part
  **   - Content-Type must be defined
  **   - if Content-Type doesn't define boundary, one is auto-generated
  **
  override Void validate()
  {
    super.validate
    if ((Obj?)parts == null) throw NullErr("no parts in ${Type.of(this).name}")
    if (parts.isEmpty) throw Err("no parts in ${Type.of(this).name}")
    if (headers["Content-Type"] == null) throw Err("Must define Content-Type header")

    // generate a boundary if not specified
    mime := MimeType.fromStr(headers["Content-Type"])
    boundary := mime.params["boundary"]
    if (boundary == null)
    {
      boundary = "_Part_${DateTime.now.ticks/1ms.ticks}.${Buf.random(4).toHex}"
      headers["Content-Type"] = mime.toStr + "; boundary=\"$boundary\""
    }
  }

  **
  ** Encode as a MIME message according to RFC 822.
  **
  override Void encode(OutStream out)
  {
    // ensure valid and configure defaults
    validate

    // get boundary
    mime := MimeType.fromStr(headers["Content-Type"])
    boundary := mime.params["boundary"]

    // write headers
    super.encode(out)

    // write out all the parts with the boundary line
    parts.each |EmailPart part|
    {
      out.print("--").print(boundary).print("\r\n")
      part.encode(out)
    }
    out.print("--").print(boundary).print("--\r\n")
  }

}