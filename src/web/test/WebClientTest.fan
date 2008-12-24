//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 08  Brian Frank  Almost Christmas!
//

**
** WebClientTest
**
class WebClientTest : Test
{

  Void testBadConfig()
  {
    verifyErr(ArgErr#) |,| { WebClient(`not/abs`) }
    verifyErr(ArgErr#) |,| { WebClient { reqUri = `/not/abs`; open } }

    verifyErr(Err#) |,| { WebClient { open } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders = Str:Str[:]; open } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders["Host"] = "bad"; open } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders["host"] = "bad"; open } }
  }

  Void testBasicGet()
  {
    // use skyfoundry.com assuming simple static HTML page served by Apache
    c := WebClient(`http://skyfoundry.com`)
    try
    {
      // status line
      c.open
      verifyEq(c.resVersion, Version("1.1"))
      verifyEq(c.resCode, 200)
      verifyEq(c.resPhrase, "OK")
      verifyEq(c.resHeaders.caseInsensitive, true)

      // response headers
      verify(c.resHeader("server").contains("Apache"))
      verify(c.resHeader("SERVER", true).contains("Apache"))
      verifyEq(c.resHeader("foo-bar", false), null)
      verifyErr(Err#) |,| { c.resHeader("foo-bar") }
      verifyErr(Err#) |,| { c.resHeader("foo-bar", true) }

      // content
      html := c.resStr
      verify(html.startsWith("<!DOCTYPE html"))
    }
    finally
    {
      c.close
    }
  }

}