//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 08  Brian Frank  Creation
//   03 Aug 15  Matthew Giannini  RFC6265
//

**
** Cookie models an HTTP cookie used to pass data between the server
** and user agent as defined by [RFC 6265]`http://tools.ietf.org/html/rfc6265`.
**
** See `WebReq.cookies` and `WebRes.cookies`.
**
@Js
const class Cookie
{

  **
  ** Parse a HTTP cookie header name/value pair. The parsing of the name-value pair
  ** is done according to the algorithm outlined in [§ 5.2]`http://tools.ietf.org/html/rfc6265#section-5.2`
  ** of the RFC.
  **
  ** Throw ParseErr or return null if not formatted correctly.
  **
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      Str? params := null
      semi := s.index(";")
      if (semi != null)
      {
        params = s[semi+1..-1]
        s = s[0..<semi]
      }

      eq := s.index("=")
      if (eq == null) throw ParseErr(s)
      name := s[0..<eq].trim
      val := s[eq+1..-1].trim

      if (params == null) return make(name, val)

      return make(name, val)
      {
        p := MimeType.parseParams(params)
        it.domain = p["Domain"]
        it.path = p.get("Path", "/")
      }
    }
    catch (Err e)
    {
      if (checked) throw ParseErr("Cookie: $s")
      return null
    }
  }

  **
  ** Construct with name and value.  The name must be a valid
  ** HTTP token and must not start with "$" (see `WebUtil.isToken`).
  ** The value string must be an ASCII string within the inclusive
  ** range of 0x20 and 0x7e (see `WebUtil.toQuotedStr`) with the
  ** exception of the semicolon.
  **
  ** Fantom cookies will use quoted string values, however some browsers
  ** such as IE won't parse a quoted string with semicolons correctly,
  ** so we make semicolons illegal.  If you have a value which might
  ** include non-ASCII characters or semicolons, then consider encoding
  ** using something like Base64:
  **
  **   // write response
  **   res.cookies.add(Cookie("baz", val.toBuf.toBase64))
  **
  **   // read from request
  **   val := Buf.fromBase64(req.cookies.get("baz", "")).readAllStr
  **
  new make(Str name, Str val, |This|? f := null)
  {
    if (f != null) f(this)
    this.name = name
    this.val = val

    // validate name
    if (!WebUtil.isToken(this.name) || this.name[0] == '$')
      throw ArgErr("Cookie name has illegal chars: $val")

    // validate value
    if (!this.val.all |Int c->Bool| { return 0x20 <= c && c <= 0x7e && c != ';'})
      throw ArgErr("Cookie value has illegal chars: $val")
    if (this.val.size + 32 >= WebUtil.maxTokenSize) // fudge room for quotes & escapes
      throw ArgErr("Cookie value too big")
  }

  **
  ** Name of the cookie.
  **
  const Str name

  **
  ** Value string of the cookie.
  **
  const Str val

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
  const Duration? maxAge

  **
  ** Specifies the domain for which the cookie is valid.
  ** An explicit domain must always start with a dot.  If
  ** null (the default) then the cookie only applies to
  ** the server which set it.
  **
  const Str? domain

  **
  ** Specifies the subset of URLs to which the cookie applies.
  ** If set to "/" (the default), then the cookie applies to all
  ** paths.  If the path is null, it as assumed to be the same
  ** path as the document being described by the header which
  ** contains the cookie.
  **
  const Str? path := "/"

  **
  ** If true, then the client only sends this cookie using a
  ** secure protocol such as HTTPS.  Defaults to false.
  **
  const Bool secure := false

  **
  ** If true, then the cookie is not available to JavaScript.
  ** Defaults to true.
  **
  const Bool httpOnly := true

  **
  ** Return the cookie formatted as an Set-Cookie HTTP header.
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
    if (httpOnly) s.add(";HttpOnly")
    return s.toStr
  }

  internal Str toNameValStr() { "$name=$val" }

}