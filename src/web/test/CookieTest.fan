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
class CookieTest : Test
{

  Void test()
  {
    verifyCookie("foo=bar", Cookie("foo", "bar"))
    verifyCookie("foo=\"bar baz\"", Cookie("foo", "bar baz"))
    verifyCookie("foo=\"_\\\"quot\\\"_\"", Cookie("foo", "_\"quot\"_"))

    verifyErr(ArgErr#) { c := Cookie("\$path", "bar") }
    verifyErr(ArgErr#) { c := Cookie("foo bar", "bar") }
    verifyErr(ArgErr#) { c := Cookie("foo", "bar\nbaz") }
    verifyErr(ArgErr#) { c := Cookie("foo", "del is \u007f") }
    verifyErr(ArgErr#) { c := Cookie("foo", "a;b;c") }
  }

  Void verifyCookie(Str s, Cookie c)
  {
    a := Cookie.fromStr(s)
    verifyEq(a.toStr, c.toStr)
    verifyEq(a.name, c.name)
    verifyEq(a.val, c.val)
    verifyEq(a.maxAge, c.maxAge)
    verifyEq(a.domain, c.domain)
    verifyEq(a.path, c.path)
  }

}