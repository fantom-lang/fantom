//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 08  Brian Frank  Creation
//

**
** SmtpErr indicates an error during an SMTP transaction.
**
const class SmtpErr : Err
{

  **
  ** Construct with error code, message, and optional cause.
  **
  new make(Int code, Str? msg, Err? cause := null)
    : super(msg, cause)
  {
    this.code = code
  }

  **
  ** Construct with SmtpRes (internal only)
  **
  internal new makeRes(SmtpRes res, Err? cause := null)
    : super.make(res.toStr, cause)
  {
    this.code = res.code
  }

  **
  ** The SMTP error code defined by RFC 2821
  **
  const Int code
}