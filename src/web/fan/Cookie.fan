//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 08  Brian Frank  Creation
//

**
** Cookie models an HTTP cookie used to pass data between
** the server and brower as defined by RFC 2965 and RFC 2109.
** See `WebReq.cookies` and `WebRes.cookies`.
**
class Cookie
{

  **
  ** Parse a HTTP cookie header name/value pair.
  ** Throw ParseErr if not formatted correctly.
  **
  static Cookie fromStr(Str s)
  {
    eq := s.index("=")
    if (eq == null) throw ParseErr(s)
    c := make
    c.name  = s[0...eq].trim
    c.value = s[eq+1..-1].trim
    return c
  }

  **
  ** Name of the cookie.  Names must be HTTP tokens
  ** and never start with '$'.
  **
  Str name

  **
  ** Value string of the cookie.
  **
  Str value

  **
  ** Provided to allow users to organize their cookies.
  ** Defaults to null.
  **
  Str comment

  **
  ** Defines the lifetime of the cookie, after the the max-age
  ** elapses the client should discard the cookie.  The duration
  ** is floored to seconds (fractional seconds are truncated).
  ** If maxAge is null (the default) then the  cookie persists
  ** until the client is shutdown.  If zero is specified, the
  ** cookie is discarded immediately.
  **
  Duration maxAge

  **
  ** Specifies the domain for which the cookie is valid.
  ** An explicit domain must always start with a dot.  If
  ** null (the default) then the cookie only applies to
  ** the server which set it.
  **
  Str domain

  **
  ** Specifies the subset of URLs to which the cookie applies.
  ** If set to "/" (the default), then the cookie applies to all
  ** paths.  If the path is null, it as assumed to be the same
  ** path as the document being described by the header which
  ** contains the cookie.
  **
  Str path := "/"

  **
  ** If true, then the client only sends this cookie using a
  ** secure protocol such as HTTPS.  Defaults to false.
  **
  Bool secure := false

  **
  ** Specified which version of HTTP statement management
  ** is being used.  Default is "1".
  **
  Str version := "1"

  **
  ** Return the cookie formatted as an HTTP header.
  **
  override Str toStr()
  {
    s := StrBuf(64)
    s.add(name).add("=").add(value)
    if (comment != null) s.add(";Comment=").add(comment)
    if (maxAge  != null) s.add(";Max-Age=").add(maxAge.toSec)
    if (domain != null) s.add(";Domain=").add(domain)
    if (path != null) s.add(";Path=").add(path)
    if (secure) s.add(";Secure")
    if (version != null) s.add(";Version=").add(version)
    return s.toStr
  }

}
