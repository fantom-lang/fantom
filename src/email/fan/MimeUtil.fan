//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 08  Brian Frank  Creation
//

using inet

**
** Utilities to deal with all the idiosyncrasies of MIME.
**
class MimeUtil
{

  **
  ** Encode the specified text into a "encoded word" according to
  ** RFC 2047.  If text is pure ASCII, then it is returned as is.
  ** Otherwise encode using UTF-8 Base64.
  **
  static Str toEncodedWord(Str text)
  {
    if (text.isAscii) return text
    return "=?UTF-8?B?" + Buf().print(text).toBase64 + "?="
  }

  **
  ** Return the addr-spec or "local@domain" part of an email
  ** address string.  Email addresses may be formatted with or
  ** without a display name:
  **   bob@acme.com
  **   Bob Smith <bob@acme.com>
  **   "Bob Smith" <bob@acme.com>
  **
  static Str toAddrSpec(Str addr)
  {
    lt := addr.index("<"); if (lt == null) return addr
    gt := addr.index(">"); if (gt == null) return addr
    return addr[lt+1..<gt].trim
  }

}