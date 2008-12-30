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
    verifyErr(ArgErr#) |,| { WebClient { reqUri = `/not/abs`; writeReq; readRes } }

    verifyErr(Err#) |,| { WebClient { writeReq; readRes } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders = Str:Str[:]; writeReq; readRes } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders["Host"] = "bad"; writeReq; readRes } }
    verifyErr(Err#) |,| { WebClient { reqUri = `http://foo/`; reqHeaders["host"] = "bad"; writeReq; readRes } }
  }

  Void testGetFixed()
  {
    // use skyfoundry.com assuming simple static HTML page served by Apache
    c := WebClient(`http://skyfoundry.com`)
    verify(!c.isConnected)
    try
    {
      // status line
      c.writeReq.readRes
      verify(c.isConnected)
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

      // fixed content-length
      len := c.resHeader("Content-Length").toInt
      html := c.resBuf
      verifyEq(html.size, len)
      verify(html.readAllStr.startsWith("<!DOCTYPE html"))
    }
    finally
    {
      c.close
    }
  }

  Void testGetChunked()
  {
    // at least for now, google home page uses chunked transfer
    c := WebClient(`http://www.google.com`)
    verify(!c.isConnected)
    try
    {
      // status line
      c.writeReq.readRes
      verify(c.isConnected)
      verifyEq(c.resVersion, Version("1.1"))
      verifyEq(c.resCode, 200)
      verifyEq(c.resPhrase, "OK")
      verifyEq(c.resHeaders.caseInsensitive, true)

      // chunked transfer
      verify(c.resHeader("Transfer-Encoding").lower.contains("chunked"))
      verify(c.resStr.contains("<html"))
    }
    finally
    {
      c.close
    }
  }

  Void testGetConvenience()
  {
    c := WebClient(`http://www.google.com`)
    verify(c.getStr.contains("<html"))
    Thread.sleep(100ms)
    verify(!c.isConnected)

    verify(c.getBuf.readAllStr.contains("<html"))
    verify(!c.isConnected)

    try
      verify(c.getIn.readAllStr.contains("<html"))
    finally
      c.close
  }

  Void testPipeline()
  {
    c := WebClient(`http://www.google.com`)
    try
    {
      c.writeReq
      c.writeReq
      c.reqUri = `http://www.google.com/bad-bad`
      c.writeReq

      c.readRes
      verifyEq(c.resCode, 200)
      verify(c.resStr.contains("<html"))

      c.readRes
      verifyEq(c.resCode, 200)
      verify(c.resStr.contains("<html"))

      c.readRes
      verifyEq(c.resCode, 404)
    }
    finally
    {
      c.close
    }

  }


}