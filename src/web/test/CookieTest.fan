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

    verifyCookie(Cookie("foo=bar"), Cookie("foo", "bar"))
    verifyCookie(Cookie("foo=\"bar baz\""), Cookie("foo", "\"bar baz\""))
    verifyCookie(Cookie("foo=\"_\\\"quot\\\"_\""), Cookie("foo", "\"_\\\"quot\\\"_\""))
    verifyCookie(Cookie.fromStr("foo=bar"), Cookie("foo", "bar"))
    verifyCookie(Cookie.fromStr("foo=bar; domain=foo.org"), Cookie("foo", "bar") {it.domain="foo.org"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org"), Cookie("foo", "bar") {it.domain="foo.org"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org; Path=/baz/"), Cookie("foo", "bar") {it.domain="foo.org";it.path="/baz/"} )
    verifyCookie(Cookie.fromStr("foo=bar; Domain=foo.org; Path=/baz/; HttpOnly"), Cookie("foo", "bar") {it.domain="foo.org";it.path="/baz/"} )

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

}
