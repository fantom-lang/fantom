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

  Void testCookies()
  {
    a := Cookie.fromStr("alpha=blah; Expires=Tue, 15-Jan-2013 21:47:38 GMT; Path=/; Domain=.example.com; HttpOnly")
    b := Cookie.fromStr("beta=belch")
    c := WebClient(`http://foo.com/`)
    c.cookies = [a]
    verifyEq(c.reqHeaders["Cookie"], "alpha=blah")
    c.cookies = [a, b]
    verifyEq(c.reqHeaders["Cookie"], "alpha=blah; beta=belch")
    c.cookies = [,]
    verifyEq(c.reqHeaders["Cookie"], null)
  }

  Void testGetFixed()
  {
    // use skyfoundry.com assuming simple static image page
    c := WebClient(`https://fantom.org/pod/fantomws/res/img/fanny-mono-grey500.svg`)
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
      verify(c.resHeader("server") != null)
      verify(c.resHeader("SERVER", true) != null)
      verifyEq(c.resHeader("foo-bar", false), null)
      verifyErr(Err#) { c.resHeader("foo-bar") }
      verifyErr(Err#) { c.resHeader("foo-bar", true) }

      // response body is SVG
      svg := c.resStr
      verify(svg.startsWith("<svg"))
    }
    finally c.close
  }

  Void testGetChunked()
  {
    c := WebClient(`https://news.ycombinator.com/`)
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

      // try again
      c.close
      again := c.getStr
      verify(again.contains("<html"))
    }
    finally c.close
  }

  Void testGetConvenience()
  {
    c := WebClient(`https://news.ycombinator.com/`)
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
      `/doc/docIntro/WhyFan.html`: `/doc/docIntro/WhyFantom`,
      `/doc/docLib/Dom.html`:      `/doc/dom/index`,
      `/doc/docLib/Email.html`:    `/doc/email/index`,
      `/doc/docLib/Fandoc.html`:   `/doc/fandoc/index`,
      `/doc/docLib/Flux.html`:     `/doc/flux/index`,
      `/doc/docLib/Fwt.html`:      `/doc/fwt/index`,
      `/doc/docLib/Json.html`:     `/doc/util/index#json`,
      `/doc/docLib/Sql.html` :     `/doc/sql/index`,
      `/doc/docLib/Web.html`:      `/doc/web/index`,
      `/doc/docLib/WebMod.html`:   `/doc/webmod/index`,
      `/doc/docLib/Wisp.html`:     `/doc/wisp/index`,
      `/doc/docLib/Xml.html`:      `/doc/xml/index`,
      `/doc/docLang/TypeDatabase.html`: `/doc/docLang/Env#index`,
    ]
    uri := map.keys.random
    base := `https://fantom.org/`
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

  /*
  Void testPipeline()
  {
    c := WebClient(`https://fantom.org/`)
    try
    {
      c.writeReq
      c.writeReq
      c.reqUri = `https://fantom.org/doc/`
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
  */

  Void testRedirectStripCreds()
  {
    // start wisp server with redirect mod
    wisp := Slot.findMethod("wisp::WispService.testSetup").call(RedirectMod())
    wisp->start
    wisp->waitUntilListening(5sec)
    port := wisp->httpPort
    try
    {
      base := `http://localhost:${port}`

      // same-origin redirect preserves Authorization and Cookie
      c := WebClient(base + `/redir?loc=/dest`)
      c.authBasic("user", "pass")
      c.reqHeaders["Cookie"] = "session=abc"
      verifyEq(c.getStr, "Authorization=yes Cookie=yes")

      // cross-origin redirect strips Authorization and Cookie
      c = WebClient(base + `/redir?loc=http://127.0.0.1:${port}/dest`)
      c.authBasic("user", "pass")
      c.reqHeaders["Cookie"] = "session=abc"
      verifyEq(c.getStr, "Authorization=no Cookie=no")
    }
    finally wisp->stop
  }

}

**************************************************************************
** RedirectMod
**************************************************************************

internal const class RedirectMod : WebMod
{
  override Void onService()
  {
    if (req.uri.pathStr == "/redir")
    {
      loc := req.uri.query["loc"] ?: "/"
      res.statusCode = 302
      res.headers["Location"] = loc
      res.headers["Content-Length"] = "0"
      res.out.flush
      return
    }

    hasAuth := req.headers["Authorization"] != null ? "yes" : "no"
    hasCookie := req.headers["Cookie"] != null ? "yes" : "no"
    body := "Authorization=$hasAuth Cookie=$hasCookie"
    res.statusCode = 200
    res.headers["Content-Type"] = "text/plain"
    res.headers["Content-Length"] = body.size.toStr
    res.out.print(body).flush
  }
}