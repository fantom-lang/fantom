#! /usr/bin/env fan
//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 21  Andy Frank  Creation
//

using dom
using util
using web
using webmod
using wisp

*************************************************************************
** JsDomMain
*************************************************************************

class JsDomMain : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.httpPort = this.port
      it.root = JsDomMod()
    }
    return runServices([wisp])
  }
}

*************************************************************************
** JsDomMod
*************************************************************************

const class JsDomMod : WebMod
{
  new make()
  {
    pods  := ["sys","dom"].map |n| { Pod.find(n) }
    files := File[,]
      .addAll(FilePack.toAppJsFiles(pods))
      .add(compileScriptJs)
    this.jsPack = FilePack(files)
  }

  override Void onGet()
  {
    switch (req.modRel.path.first)
    {
      case null:     onIndex
      case "dom.js": jsPack.onGet
    }
  }

  Void onIndex()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType5
    out.html
    out.head
      .title.w("Dom Basics").titleEnd
      .includeJs(`/dom.js`)
      .style.w(
        "body {
           padding: 0.25em 2em;
           font: 16px -apple-system, BlinkMacSystemFont, sans-serif;
         }").styleEnd
    out.headEnd
    out.body
      .h1.w("Dom Basics").h1End

    // Win
    out.hr
      .h2.w("Win").h2End
      .p
        .button("value='Alert'    onclick='fan.domExample.JsDom.winAlert()'")
        .button("value='Uri'      onclick='fan.domExample.JsDom.winUri()'")
        .button("value='Viewport' onclick='fan.domExample.JsDom.winViewport()'")
        .pEnd

    // Elem
    out.hr
      .h2.w("Elem").h2End
      .p
        .button("value='Add Item' onclick='fan.domExample.JsDom.elemAddItem()'")
        .button("value='Clear Items' onclick='fan.domExample.JsDom.elemClearItems()'")
        .pEnd
      .div("id='elem-list'").divEnd

    out.bodyEnd
    out.htmlEnd
  }

  **
  ** Normally your @Js code would exist in a pod, but since
  ** this is a Fantom script, we need to compile on the fly
  ** in order to get JS output to add to FilePack.
  **
  private File compileScriptJs()
  {
    src  := Env.cur.homeDir + `examples/js/dom.fan`
    js   := Env.cur.compileScriptToJs(src, ["podName":"domExample"])
    temp := Env.cur.tempDir + `dom.js`
    temp.out.print(js).sync.close
    return temp
  }

  private const FilePack jsPack
}

*************************************************************************
** JsDom
*************************************************************************

@Js class JsDom
{
  static Void winAlert()
  {
    Win.cur.alert("Hello world, from JsDom.winAlert!")
  }

  static Void winUri()
  {
    Win.cur.alert("uri: ${Win.cur.uri}")
  }

  static Void winViewport()
  {
    Win.cur.alert("viewport: ${Win.cur.viewport}")
  }

  static Void elemAddItem()
  {
    list := Win.cur.doc.elemById("elem-list")
    list.add(Elem {
      it.text = "This is item #${list.children.size}"
    })
  }

  static Void elemClearItems()
  {
    list := Win.cur.doc.elemById("elem-list")
    list.removeAll
  }
}
