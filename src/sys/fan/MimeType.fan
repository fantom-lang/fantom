//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 08  Brian Frank  Creation
//

**
** MimeType represents the parsed value of a Content-Type
** header per RFC 2045 section 5.1.
**
@Serializable { simple = true }
const final class MimeType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse from string format.  If invalid format and
  ** checked is false return null, otherwise throw ParseErr.
  ** Parenthesis comments are not supported.
  **
  static MimeType? fromStr(Str s, Bool checked := true)

  **
  ** Parse a set of attribute-value parameters where the
  ** values may be tokens or quoted-strings.  The resulting map
  ** is case insensitive.  If invalid format and checked is
  ** false return null, otherwise throw ParseErr.  Parenthesis
  ** comments are not supported.
  **
  ** Examples:
  **   a=b; c="d"  =>  ["a":"b", "c"="d"]
  **
  static [Str:Str]? parseParams(Str s, Bool checked := true)

  **
  ** Map a case insensitive file extension to a MimeType.
  ** This mapping is configured via "etc/sys/ext2mime.props".  If
  ** no mapping is available return null.
  **
  static MimeType? forExt(Str ext)

  **
  ** Private constructor - must use fromStr
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Hash code is derived from the mediaType, subType,
  ** and params hashes.
  **
  override Int hash()

  **
  ** Equality is based on the case insensitive mediaType
  ** and subType, and params (keys are case insensitive
  ** and values are case sensitive).
  **
  override Bool equals(Obj? that)

  **
  ** Encode as a MIME message according to RFC 822.  This
  ** is always the exact same string passed to `fromStr`.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// MIME Type
//////////////////////////////////////////////////////////////////////////

  **
  ** The primary media type always in lowercase:
  **   text/html  =>  text
  **
  Str mediaType()

  **
  ** The subtype always in lowercase:
  **   text/html  =>  html
  **
  Str subType()

  **
  ** Additional parameters stored in case-insensitive map.
  ** If no parameters, then this is an empty map.
  **   text/html; charset=utf-8    =>  [charset:utf-8]
  **   text/html; charset="utf-8"  =>  [charset:utf-8]
  **
  Str:Str params()

  **
  ** If a charset parameter is specified, then map it to
  ** the 'Charset' instance, otherwise return 'Charset.utf8'.
  **
  Charset charset()

}