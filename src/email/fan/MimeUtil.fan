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
  ** address string.  The result is always returned as "<addr>".
  ** The addresses may be formatted with or without a display name:
  **
  **   bob@acme.com                =>  <bob@acme.com>
  **   Bob Smith <bob@acme.com>    =>  <bob@acme.com>
  **   "Bob Smith" <bob@acme.com>  =>  <bob@acme.com>
  **
  static Str toAddrSpec(Str addr)
  {
    addr = addr.trim
    lt := addr.index("<")
    gt := addr.index(">")
    if (lt != null && gt != null) return addr[lt..gt]
    return "<$addr>"
  }

  **
  ** Write a MIME header formatted as "name: body\r\n".
  ** NOTE: hook to potentially fold header lines over 1000 here
  **
  internal static Void encodeHeader(OutStream out, Str name, Str val)
  {
    out.print(name).print(": ").print(val).print("\r\n")
  }

}