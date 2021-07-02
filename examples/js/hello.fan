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
** JsHelloMain
*************************************************************************

class JsHelloMain : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.httpPort = this.port
      it.root = JsHelloMod()
    }
    return runServices([wisp])
  }
}

*************************************************************************
** JsHelloMod
*************************************************************************

const class JsHelloMod : WebMod
{
  new make()
  {
    pods  := ["sys"].map |n| { Pod.find(n) }
    files := File[,]
      .addAll(FilePack.toAppJsFiles(pods))
      .add(compileScriptJs)
    this.jsPack = FilePack(files)
  }

  override Void onGet()
  {
    switch (req.modRel.path.first)
    {
      case null:       onIndex
      case "hello.js": jsPack.onGet
    }
  }

  Void onIndex()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType5
    out.html
    out.head
      .title.w("Hello World, from Fantom JS!").titleEnd
      .initJs(["main":"hello::JsHello"])
      .includeJs(`/hello.js`)
      .style.w(
        "body {
           padding: 0.25em 2em;
           font: 16px -apple-system, BlinkMacSystemFont, sans-serif;
         }").styleEnd
    out.headEnd
    out.body
      .h1.w("Hello World, from Fantom JS!").h1End
      .p.w("Check your JavaScript console for <code>echo()</code> output").pEnd
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
    src  := Env.cur.homeDir + `examples/js/hello.fan`
    js   := Env.cur.compileScriptToJs(src, ["podName":"hello"])
    temp := Env.cur.tempDir + `dom.js`
    temp.out.print(js).sync.close
    return temp
  }

  private const FilePack jsPack
}

*************************************************************************
** JsHello
*************************************************************************

@Js class JsHello
{
  static Void main()
  {
    echo("Hello there! This is from JsHello!")
  }
}
