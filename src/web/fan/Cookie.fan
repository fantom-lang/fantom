//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 08  Brian Frank  Creation
//

**
** Cookie models an HTTP cookie used to pass data between the server
** and brower as defined by the original Netscape cookie specification
** and RFC 2109.  Note the newer RFC 2965 is unsupported by most browsers,
** and even 2109 isn't really supported by some of the major browsers.
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
    c.@name = s[0...eq].trim
    c.@val  = s[eq+1..-1].trim
    return c
  }

  **
  ** Name of the cookie.  Throw ArgErr on set if name is not
  ** a valid HTTP token or starts with "$" - see `WebUtil.isToken`.
  **
  Str name
  {
    set
    {
      if (!WebUtil.isToken(val) || val[0] == '$')
        throw ArgErr("Cookie name has illegal chars: $val")
      @name = val
    }
  }

  **
  ** Value string of the cookie.  Throw ArgErr on set if
  ** value is not a valid HTTP token - see `WebUtil.isToken`.
  **
  Str val
  {
    set
    {
      if (!WebUtil.isToken(val))
        throw ArgErr("Cookie value has illegal chars: $val")
      @val = val
    }
  }

  **
  ** Defines the lifetime of the cookie, after the the max-age
  ** elapses the client should discard the cookie.  The duration
  ** is floored to seconds (fractional seconds are truncated).
  ** If maxAge is null (the default) then the  cookie persists
  ** until the client is shutdown.  If zero is specified, the
  ** cookie is discarded immediately.  Note that many browsers
  ** still don't recognize max-age, so setting max-age also
  ** always includes an expires attribute.
  **
  Duration? maxAge

  **
  ** Specifies the domain for which the cookie is valid.
  ** An explicit domain must always start with a dot.  If
  ** null (the default) then the cookie only applies to
  ** the server which set it.
  **
  Str? domain

  **
  ** Specifies the subset of URLs to which the cookie applies.
  ** If set to "/" (the default), then the cookie applies to all
  ** paths.  If the path is null, it as assumed to be the same
  ** path as the document being described by the header which
  ** contains the cookie.
  **
  Str? path := "/"

  **
  ** If true, then the client only sends this cookie using a
  ** secure protocol such as HTTPS.  Defaults to false.
  **
  Bool secure := false

  **
  ** Return the cookie formatted as an HTTP header.
  **
  override Str toStr()
  {
    s := StrBuf(64)
    s.add(name).add("=").add(val)
    if (maxAge != null)
    {
      // we need to use Max-Age *and* Expires since many browsers
      // such as Safari and IE still don't recognize max-age
      s.add(";Max-Age=").add(maxAge.toSec)
      if (maxAge.ticks <= 0)
        s.add(";Expires=").add("Sat, 01 Jan 2000 00:00:00 GMT")
      else
        s.add(";Expires=").add((DateTime.nowUtc+maxAge).toHttpStr)
    }
    if (domain != null) s.add(";Domain=").add(domain)
    if (path != null) s.add(";Path=").add(path)
    if (secure) s.add(";Secure")
    return s.toStr
  }

}