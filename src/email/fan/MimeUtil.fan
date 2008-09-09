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

}