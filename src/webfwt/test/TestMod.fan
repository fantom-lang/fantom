//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**************************************************************************
** UiTesterMod
**************************************************************************

internal const class UiTesterMod : WebMod
{
  override Void onService()
  {
    switch (req.uri.path.first)
    {
      case null:         onIndex
      case "pod":        onPod
      case "button":     onButton
      case "list":       onList
      case "transition": onTransition
      case "upload":     onUpload
      case "scroll":     onScroll
      default:           res.sendErr(404)
    }
  }

  private Void onIndex()
  {
    res.headers["Content-Type"] = "text/html; charset=UTF-8"
    out := res.out
    out.printLine("<!DOCTYPE html>")
    out.html
    out.head.title.w("WebFwt UiTester").titleEnd.headEnd
    out.body
      .h1.w("WebFwt UiTester").h1End
      .ul
        .li.a(`button`).w("StyledButton").aEnd.liEnd
        .li.a(`list`).w("WebList").aEnd.liEnd
        .li.a(`transition`).w("TransitionPane").aEnd.liEnd
        .li.a(`upload`).w("File Upload").aEnd.liEnd
        .li.a(`scroll`).w("WebScrollPane").aEnd.liEnd
      .ulEnd
    out.bodyEnd
    out.htmlEnd
  }

  private Void onPod()
  {
    File file := ("fan://" + req.uri.toStr[5..-1]).toUri.get
    if (!file.exists) { res.sendErr(404); return }
    FileWeblet(file).onService
  }

  private Void onButton()
  {
    fwt("StyledButton : WebFwt UiTester", "webfwt::StyledButtonTest")
  }

  private Void onList()
  {
    fwt("WebList : WebFwt UiTester", "webfwt::WebListTest")
  }

  private Void onTransition()
  {
    fwt("TransitionPane : WebFwt UiTester", "webfwt::TransitionPaneTest")
  }

  private Void onUpload()
  {
    if (req.method == "GET")
    {
      fwt("FileUpload : WebFwt UiTester", "webfwt::FileUploadTest")
    }
    else
    {
      name := req.headers["FileUpload-filename"]
      buf  := req.in.readAllBuf
      //buf  := Buf(); while (req.in.readBuf(buf, 512) != null) { Slot.find("concurrent::Actor.sleep")->call(50ms) }
      echo("# headers:")
      echo(req.headers.join("\n") |v,n| { "#   $n: $v" })
      echo("# uploaded $buf.size bytes")
      // echo(buf.readAllStr)
      echo("#")

      res.statusCode = 200
      res.headers["Content-Type"] = "text/plain; charset=UTF-8"
      res.out.print("loaded!").flush.close
    }
  }

  private Void onScroll()
  {
    fwt("WebScrollPane : WebFwt UiTester", "webfwt::WebScrollPaneTest")
  }

  private Void fwt(Str title, Str test)
  {
    podUri := `/pod/`
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.printLine("<!DOCTYPE html>")
    out.html
    out.head
      out.title.esc(title).titleEnd
      out.style.w(
       "body { font:10pt Lucida Grande, Arial; }
        a { color:#3d80df; }
        ").styleEnd
      out.includeJs(podUri + `sys/sys.js`)
      out.includeJs(podUri + `concurrent/concurrent.js`)
      out.includeJs(podUri + `util/util.js`)
      out.includeJs(podUri + `web/web.js`)
      out.includeJs(podUri + `gfx/gfx.js`)
      out.includeJs(podUri + `dom/dom.js`)
      out.includeJs(podUri + `fwt/fwt.js`)
      out.includeJs(podUri + `webfwt/webfwt.js`)
      WebUtil.jsMain(out, "webfwt::UiTesterMain", ["test":test])
    out.headEnd
    out.body
    out.bodyEnd
    out.htmlEnd
  }
}

**************************************************************************
** UiTesterPane
**************************************************************************
@Js
internal class UiTesterMain
{
  Void main()
  {
    test := Env.cur.vars["test"]
    type := Type.find(test)
    win  := Window()
    win.content = type.make
    win.open
  }
}
