#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Apr 08  Brian Frank  Creation
//

using fand
using web
using webapp
using wisp

**
** Boot script for weblet hello world
**
class Boot : BootScript
{
  override Service[] services :=
  [
    WispService
    {
      port = 8080
      pipeline = [FindResourceStep {}, FindViewStep {}, ServiceViewStep {}]
    }
  ]

  override Void setup()
  {
    UriSpace.root.create(`/homePage`, Hello#)
  }
}

class Hello : Weblet
{
  override Void onGet()
  {
    text := "hello world #4"
    res.headers["Content-Type"] = "text/plain; charset=utf-8"
    res.headers["Content-Length"] = text.size.toStr
    res.out.print(text)
  }
}