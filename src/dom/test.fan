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
  @opt="http port"
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
    else res.sendError(404)
  }

  Void onIndex()
  {
    if (req.method != "GET") { res.sendError(501); return }
    res.headers["Content-Type"] = "text/html"
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
    if (req.method != "GET") { res.sendError(501); return }
    File file := ("fan:/sys" + req.uri).toUri.get
    if (!file.exists) { res.sendError(404); return }
    FileWeblet(file).onService
  }
}

/*
using fand
using wisp
using web
using webapp
using testWeb

class Boot : BootScript
{
  override Service[] services :=
  [
    // WebService
    WispService
    {
      port = 8080
      pipeline =
      [
        FindResourceStep {},
        FindViewStep {},
        ServiceViewStep {},
      ]
    },
  ]

  override Void setup()
  {
    UriSpace.root.create(`/homePage`, Index#)
    UriSpace.root.create(`/dom`,      DomTest#)
    UriSpace.root.create(`/domFx`,    DomFxTest#)
    UriSpace.root.create(`/call`,     CallTest#)
  }
}

class Index : Widget
{
  override Void onGet()
  {
    head.title.w("testWeb Tests").titleEnd
    body.h1.w("testWeb Tests").h1End
    body.ul
    body.li.a(`/dom`).w("dom unit tests").aEnd.liEnd
    body.li.a(`/domFx`).w("domFx tests").aEnd.liEnd
    body.li.a(`/call`).w("Call tests").aEnd.liEnd
    body.ulEnd
  }
}
*/