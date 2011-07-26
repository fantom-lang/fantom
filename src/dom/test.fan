#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using util
using dom
using web
using webmod
using wisp

class DomTestMain : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.port = this.port
      it.root = DomTestMod()
    }
    return runServices([wisp])
  }
}

const class DomTestMod : WebMod
{
  override Void onService()
  {
    name := req.modRel.path.first
    if (name == null) onIndex
    else if (name == "pod") onPodFile
    else if (name == "dom") DomTest().onService
    else res.sendErr(404)
  }

  Void onIndex()
  {
    if (req.method != "GET") { res.sendErr(501); return }
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("Dom Test").titleEnd
      .headEnd
    out.body
      .h1.w("Dom Test").h1End
      .ul
        .li.a(`/dom`).w("Dom").aEnd.liEnd
      .ulEnd
      .bodyEnd
    out.htmlEnd
  }

  Void onPodFile()
  {
    // serve up pod resources
    if (req.method != "GET") { res.sendErr(501); return }
    File file := ("fan://" + req.uri.toStr["/pod/".size..-1]).toUri.get
    if (!file.exists) { res.sendErr(404); return }
    FileWeblet(file).onService
  }
}

