//
// Copyright (c) 2015, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   13 Feb 2015  Brian Frank  Creation
//

using compilerJs
using util
using web
using wisp

class Main : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.httpPort = this.port
      it.root = DomkitTestMod()
    }
    return runServices([wisp])
  }
}

const class DomkitTestMod : WebMod
{
  override Void onService()
  {
    n := req.modRel.path.first
    switch (n)
    {
      case null:       onIndex
      case "test":     onTest
      case "pod":      onPod
      case "units.js": onUnits
      case "tz.js":    onTz
      default:         res.sendErr(404)
    }
  }

  Void onIndex()
  {
    if (req.method != "GET") { res.sendErr(501); return }
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("Domkit Test").titleEnd
      .headEnd
    out.body
      .h1.w("Domkit Test").h1End
      .ul

    DomkitTest.list.each |t|
    {
      out.li.a(`/test/$t.name`).w(t.name).aEnd.liEnd
    }

    out.ulEnd.bodyEnd.htmlEnd
  }

  Void onTest()
  {
    name := req.modRel.path.getSafe(1) ?: ""
    type := typeof.pod.type(name, false)
    if (type == null || !type.fits(DomkitTest#)) { res.sendErr(404); return }

    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("Domkit Test").titleEnd
      .includeCss(`/pod/domkit/res/css/domkit.css`)
      .includeJs(`/pod/sys/sys.js`)
      .includeJs(`/tz.js`)
      .includeJs(`/units.js`)
      .includeJs(`/pod/util/util.js`)
      .includeJs(`/pod/concurrent/concurrent.js`)
      .includeJs(`/pod/web/web.js`)
      .includeJs(`/pod/gfx/gfx.js`)
      .includeJs(`/pod/dom/dom.js`)
      .includeJs(`/pod/domkit/domkit.js`)
      .includeJs(`/pod/testDomkit/testDomkit.js`)
      .style.w(
       ".hidden { display: none; }")
      .styleEnd

      env := Str:Str[:]
      env["ui.test.qname"] = type.qname

      WebUtil.jsMain(out, "testDomkit::DomkitTest", env)

    out.headEnd

    out.body.bodyEnd
    out.htmlEnd
  }

  Void onPod()
  {
    if (req.method != "GET") { res.sendErr(501); return }
    File file := ("fan://" + req.uri.pathOnly.toStr["/pod/".size..-1]).toUri.get
    if (!file.exists) { res.sendErr(404); return }
    FileWeblet(file).onService
  }

  Void onUnits()
  {
    res.headers["Content-Type"] = "text/javascript; charset=utf-8"
    JsUnitDatabase().write(res.out)
  }

  Void onTz()
  {
    res.headers["Content-Type"] = "text/javascript; charset=utf-8"
    res.out.writeBuf((Env.cur.homeDir + `etc/sys/tz.js`).readAllBuf)
  }
}