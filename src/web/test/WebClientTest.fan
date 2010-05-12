//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 08  Brian Frank  Almost Christmas!
//

using concurrent

**
** WebClientTest
**
class WebClientTest : Test
{

  Void testBadConfig()
  {
    verifyErr(ArgErr#) { x := WebClient(`not/abs`) }
    verifyErr(ArgErr#) { x := WebClient { reqUri = `/not/abs`; writeReq; readRes } }

    verifyErr(Err#) { x := WebClient { writeReq; readRes } }
    verifyErr(Err#) { x := WebClient { reqUri = `http://foo/`; reqHeaders = Str:Str[:]; writeReq; readRes } }
    verifyErr(Err#) { x := WebClient { reqUri = `http://foo/`; reqHeaders["Host"] = "bad"; writeReq; readRes } }
    verifyErr(Err#) { x := WebClient { reqUri = `http://foo/`; reqHeaders["host"] = "bad"; writeReq; readRes } }
  }

  Void testGetFixed()
  {
    // use skyfoundry.com assuming simple static image page
    c := WebClient(`http://skyfoundry.com/pub/img/database.png`)
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
      verify(c.resHeader("server").contains("nginx"))
      verify(c.resHeader("SERVER", true).contains("nginx"))
      verifyEq(c.resHeader("foo-bar", false), null)
      verifyErr(Err#) { c.resHeader("foo-bar") }
      verifyErr(Err#) { c.resHeader("foo-bar", true) }

      // fixed content-length
      len := c.resHeader("Content-Length").toInt
      png := c.resBuf
      verifyEq(png[1].toChar, "P")
      verifyEq(png[2].toChar, "N")
      verifyEq(png[3].toChar, "G")
    }
    finally c.close
  }

  Void testGetChunked()
  {
    // at least for now, google home page uses chunked transfer
    c := WebClient(`http://google.com`)
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
    finally c.close
  }

  Void testGetConvenience()
  {
    c := WebClient(`http://google.com`)
    verify(c.getStr.contains("<html"))
    Actor.sleep(100ms)
    verify(!c.isConnected)

    buf := c.getBuf
    cs := MimeType(c.resHeaders["Content-Type"]).charset
    verify(buf { charset = cs }.readAllStr.contains("<html"))
    verify(!c.isConnected)

    try
      verify(c.getIn.readAllStr.contains("<html"))
    finally
      c.close
  }

  Void testRedirects()
  {
    // google redirect to www or country specific URL
    verifyRedirect(`http://google.com`, null)

    // pick a random URI from one of the pages on fantom.org;
    // this both tests redirects and ensures that these URIs are
    // always maintained
    map :=
    [
      `/doc/docIntro/WhyFan.html`: `/doc/docIntro/WhyFantom.html`,
      `/doc/docLib/Dom.html`:      `/doc/dom/pod-doc.html`,
      `/doc/docLib/Email.html`:    `/doc/email/pod-doc.html`,
      `/doc/docLib/Fandoc.html`:   `/doc/fandoc/pod-doc.html`,
      `/doc/docLib/Flux.html`:     `/doc/flux/pod-doc.html`,
      `/doc/docLib/Fwt.html`:      `/doc/fwt/pod-doc.html`,
      `/doc/docLib/Json.html`:     `/doc/util/pod-doc.html#json`,
      `/doc/docLib/Sql.html` :     `/doc/sql/pod-doc.html`,
      `/doc/docLib/Web.html`:      `/doc/web/pod-doc.html`,
      `/doc/docLib/WebMod.html`:   `/doc/webmod/pod-doc.html`,
      `/doc/docLib/Wisp.html`:     `/doc/wisp/pod-doc.html`,
      `/doc/docLib/Xml.html`:      `/doc/xml/pod-doc.html`,
      `/doc/docLang/TypeDatabase.html`: `/doc/docLang/Env.html#index`,
    ]
    uri := map.keys.random
    base := `http://fantom.org/`
    verifyRedirect(base + uri, base + map[uri])
  }

  Void verifyRedirect(Uri origUri, Uri? expected)
  {
    c := WebClient(origUri)
    try
    {
      // disable auto redirects
      c.followRedirects = false
      c.writeReq.readRes
      verifyEq(c.resCode/100, 3)
      c.close

      // now enable auto redirects to true and try again
      c.followRedirects = true
      c.writeReq.readRes
      verifyEq(c.resCode, 200)
      verifyNotEq(c.reqUri, origUri)
      if (expected != null) verifyEq(c.reqUri, expected)
    }
    finally c.close
  }

  Void testPipeline()
  {
    c := WebClient(`http://fantom.org`)
    try
    {
      c.writeReq
      c.writeReq
      c.reqUri = `http://fantom.org/bad-bad`
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
    finally c.close
  }

}