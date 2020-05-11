//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using compilerJs
using util
using web
using wisp

class Main : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Opt { help = "apply sample css" }
  Bool css := false

  override Int run()
  {
    wisp := WispService
    {
      it.httpPort = this.port
      it.root = DomkitTestMod { it.useSampleCss=css }
    }
    return runServices([wisp])
  }
}

const class DomkitTestMod : WebMod
{
  new make(|This| f)
  {
    f(this)
    pods := [typeof.pod]
    this.jsPack  = FilePack(FilePack.toAppJsFiles(pods))
    this.cssPack = FilePack(FilePack.toAppCssFiles(pods))
  }

  const Bool useSampleCss := false

  const FilePack jsPack

  const FilePack cssPack

  override Void onService()
  {
    n := req.modRel.path.first
    switch (n)
    {
      case null:       onIndex
      case "test":     onTest
      case "app.js":   jsPack.onService
      case "app.css":  cssPack.onService
      case "pod":      onPod
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
      .includeCss(`/app.css`)
      .includeJs(`/app.js`)
      .style.w(
       "html { height: 100%; }
        body {
          height: 100%;
          overflow: hidden;
          font: 14px 'Helvetica Neue', Arial, sans-serif;
          padding: 0;
          margin: 0;
          background: #fff;
          color: #333;
          line-height: 1.5;  /* for testing domkit-control */
        }")
      .styleEnd

      if (useSampleCss) out.style.w(sampleCss).styleEnd

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

  const Str sampleCss :=
 """.domkit-sel {
      background-color: #dcdcdc !important;
    }

    :focus .domkit-sel, .domkit-sel.pin {
      background-color: #8e44ad !important;
      color: #fff !important;
    }

    :focus .domkit-sel a {
      color: #fff !important;
    }

    .domkit-control {
      font: 16px 'Helvetica Neue', Arial, sans-serif;
    }

    .domkit-control-button {
      background: #f8f8f8;
      border: 1px solid #444;
      border-radius: 5px;
    }

    .domkit-control-button:hover { background: #f0f0f0; }
    .domkit-control-button.down  { background: #ccc; }
    .domkit-control-button.selected,
    .domkit-control-button.selected:hover {
      color: #fff;
      background-color: #8e44ad;
      border-color: #6d2f87;
    }

    .domkit-control-text {
      background: #fff;
      border: 1px solid #444;
      border-radius: 5px;
    }

    .domkit-control-button:focus, .domkit-control-text:focus {
      border-color: #8e44ad;
    }

    div.domkit-Table-header {
      font: bold 13px 'Helvetica Neue', Arial, sans-serif;
    }
    div.domkit-Table-cell {
      font: 14px 'Helvetica Neue', Arial, sans-serif;
    }
    div.domkit-Table-cell.odd  { background: #fff; }
    div.domkit-Table-cell.even { background: #f8f8f8; }

    div.domkit-Tree {
      font: 16px 'Helvetica Neue', Arial, sans-serif;
    }

    div.domkit-Dialog-frame {
      background: #fff;
      border: 1px solid #ccc;
      border-radius: 5px;
      box-shadow: 0px 12px 32px rgba(0, 0, 0, 0.4);
    }

    div.domkit-Dialog-title {
      text-align: center;
      font-weight: bold;
      background: #f8f8f8;
      border-bottom: 1px solid #ccc;
    }

    div.domkit-Dialog-mask {
      background: rgba(0, 0, 0, 0.25);
    }

    div.domkit-Popup {
      background: #fff;
      border: 1px solid #ccc;
      border-radius: 5px;
      box-shadow: 0px 9px 18px rgba(0, 0, 0, 0.25);
    }

    div.domkit-Popup-mask {
      background: none;
    }
    """
}