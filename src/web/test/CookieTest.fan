//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   07 Feb 09  Brian Frank  Creation
//

**
** CookieTest
**
@Js
class CookieTest : Test
{

  Void test()
  {
    // used by WebReq.cookies
    s := "Bugzilla_login=28; VERSION-foo%2Fbar=unspecified; __u=1303429918|un=(referral)|ud=referral"
    verifyEq(MimeType.parseParams(s),
      ["Bugzilla_login": "28",
       "VERSION-foo%2Fbar": "unspecified",
       "__u": "1303429918|un=(referral)|ud=referral"])

    // test key=(no val)
    s = "mm_testcookie_storage=; foobar=123; _ga_DGW3P9MPX4=GS1.2.1720526761"
    verifyEq(MimeType.parseParams(s),
      ["mm_testcookie_storage": "",
       "foobar": "123",
       "_ga_DGW3P9MPX4": "GS1.2.1720526761"])

    verifyCookie(Cookie("foo=bar"), Cookie("foo", "bar"))
    verifyCookie(Cookie("foo=\"bar baz\""), Cookie("foo", "\"bar baz\""))
    verifyCookie(Cookie("foo=\"_\\\"quot\\\"_\""), Cookie("foo", "\"_\\\"quot\\\"_\""))
    verifyCookie(Cookie.fromStr("foo=bar"), Cookie("foo", "bar"))
    verifyCookie(Cookie.fromStr("foo=bar; domain=foo.org"), Cookie("foo", "bar") {it.domain="foo.org"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org"), Cookie("foo", "bar") {it.domain="foo.org"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org; Path=/baz/"), Cookie("foo", "bar") {it.domain="foo.org";it.path="/baz/"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org; Path=/baz/; HttpOnly"), Cookie("foo", "bar") {it.domain="foo.org";it.path="/baz/"} )

    // Max-Age parsing; takes precedence over Expires
    verifyEq(Cookie.fromStr("foo=bar; Max-Age=3600").maxAge, 1hr)
    verifyEq(Cookie.fromStr("foo=bar; Max-Age=0").maxAge, 0sec)
    verifyEq(Cookie.fromStr("foo=bar; Max-Age=-1").maxAge, 0sec)
    verifyEq(Cookie.fromStr("foo=bar; Max-Age=bad").maxAge, null)
    future := (DateTime.nowUtc + 1day).toHttpStr
    verifyEq(Cookie.fromStr("foo=bar; Max-Age=0; Expires=$future").maxAge, 0sec)

    // Expires in the past is a delete, future is non-zero
    verifyEq(Cookie.fromStr("foo=bar; Expires=Sat, 01 Jan 2000 00:00:00 GMT").maxAge, 0sec)
    verify(Cookie.fromStr("foo=bar; Expires=$future").maxAge > 23hr)
    verifyEq(Cookie.fromStr("foo=bar; Expires=bad").maxAge, null)
    verifyEq(Cookie.fromStr("foo=bar").maxAge, null)

    verifyErr(ParseErr#) { c := Cookie.fromStr("=bar") }
    verifyErr(ArgErr#) { c := Cookie("\$path", "bar") }
    verifyErr(ArgErr#) { c := Cookie("foo bar", "bar") }
    verifyErr(ArgErr#) { c := Cookie("foo", "bar\nbaz") }
    verifyErr(ArgErr#) { c := Cookie("foo", "del is \u007f") }
    verifyErr(ArgErr#) { c := Cookie("foo", "a;b;c") }
  }

  Void verifyCookie(Cookie a, Cookie b)
  {
    verifyEq(a.toStr, b.toStr)
    verifyEq(a.name, b.name)
    verifyEq(a.val, b.val)
    verifyEq(a.maxAge, b.maxAge)
    verifyEq(a.domain, b.domain)
    verifyEq(a.path, b.path)
  }

  Void testSession()
  {
    // verify with no overrides defined in etc/web/config.props
    c := Cookie.makeSession("key", "val")
    verifyEq(c.name, "key")
    verifyEq(c.val, "val")
    verifyEq(c.httpOnly, true)
    verifyEq(c.secure, false)
    verifyEq(c.sameSite, "strict")

    // verify with overrides to method
    c = Cookie.makeSession("key", "val", [Cookie#secure:true])
    verifyEq(c.name, "key")
    verifyEq(c.val, "val")
    verifyEq(c.httpOnly, true)
    verifyEq(c.secure, true)
    verifyEq(c.sameSite, "strict")
  }

}

