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
** JsEnvMain
*************************************************************************

class JsEnvMain : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.httpPort = this.port
      it.root = JsEnvMod()
    }
    return runServices([wisp])
  }
}

*************************************************************************
** JsEnvMod
*************************************************************************

const class JsEnvMod : WebMod
{
  new make()
  {
    // app runtime js
    pods := ["sys", "dom"].map |n| { Pod.find(n) }
    app  := File[,]
      .addAll(FilePack.toAppJsFiles(pods))
      .add(compileScriptJs)

    // additional locales to include (en-US is already included by sys.js)
    loc := ["es", "fr", "de"].map |n| {
      FilePack.toLocaleJsFile(Locale(n))
    }

    this.appPack = FilePack(app)
    this.locPack = FilePack(loc)
  }

  override Void onGet()
  {
    switch (req.modRel.path.first)
    {
      case null:     onIndex
      case "app.js": appPack.onGet
      case "loc.js": locPack.onGet
    }
  }

  Void onIndex()
  {
    //
    // Modify or comment out to change booted env:
    //  * if no tz is specified; query browser for current tz
    //  * locale must be served in locPack; see make ctor
    //
    env := [
      "main":     "env::JsEnv",
      "timezone": "Los_Angeles",
      "locale":   "fr"
    ]

    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType5
    out.html
    out.head
      .title.w("JS Env").titleEnd
      .initJs(env)
      .includeJs(`/app.js`)
      .includeJs(`/loc.js`)
      .style.w(
        "body {
           padding: 0.25em 2em;
           font: 16px -apple-system, BlinkMacSystemFont, sans-serif;
         }
         hr {
           border: none;
           background: #d9d9d9;
           height: 1px;
           margin: 1em 0;
         }
         pre {
           background: #f2f6f9;
           padding: 1em;
           border-radius: 5px;
         }
         table {
           border-collapse: collapse;
           border: 1px solid #d9d9d9;
         }
         td { padding: 0.5em 1em; }
         td + td { border-left: 1px solid #d9d9d9; }
         ").styleEnd
    out.headEnd
    out.body
      .h1.w("JS Env").h1End
      .hr
      .p.w("Env.vars (edit in JsEnvMod.onIndex):").pEnd
      .pre("id='env-vars'").preEnd
      .hr
      .table
        .tr.td.w("TimeZone.cur").tdEnd  .td("id='tz-cur'").tdEnd.trEnd
        .tr.td.w("DateTime.now").tdEnd  .td("id='dt-now'").tdEnd.trEnd
        .tr.td.w("DateTime.boot").tdEnd .td("id='dt-boot'").tdEnd.trEnd
        .tr.td.w("Locale.cur").tdEnd    .td("id='loc-cur'").tdEnd.trEnd
        .tr.td.w("Locale Month").tdEnd  .td("id='loc-mon'").tdEnd.trEnd
        .tr.td.w("Locale Weekday").tdEnd.td("id='loc-wd'").tdEnd.trEnd
        .tableEnd
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
    src  := Env.cur.homeDir + `examples/js/env.fan`
    js   := Env.cur.compileScriptToJs(src, ["podName":"env"])
    temp := Env.cur.tempDir + `env.js`
    temp.out.print(js).sync.close
    return temp
  }

  private const FilePack appPack
  private const FilePack locPack
}

*************************************************************************
** JsEnv
*************************************************************************

@Js class JsEnv
{
  static Void main()
  {
    doc := Win.cur.doc
    doc.elemById("env-vars").text = Env.cur.vars.toStr

    // timezone
    doc.elemById("tz-cur").text  = TimeZone.cur.toStr
    doc.elemById("dt-now").text  = DateTime.now.toLocale
    doc.elemById("dt-boot").text = DateTime.boot.toLocale

    // locale
    doc.elemById("loc-cur").text = Locale.cur.toStr
    doc.elemById("loc-mon").text = Date.today.month.localeFull
    doc.elemById("loc-wd").text  = Date.today.weekday.localeFull

    Win.cur.setInterval(1sec) {
      doc.elemById("dt-now").text = DateTime.now.toLocale
    }
  }
}
