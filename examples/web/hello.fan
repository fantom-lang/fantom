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
      root = HelloMod()
    }
  ]
}

const class HelloMod : WebMod
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/plain; charset=utf-8"
    res.out.print("hello world #4")
  }
}