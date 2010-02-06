#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Apr 08  Brian Frank  Creation
//

using util
using web
using wisp

**
** Boot script for web hello world
**
class WebHello : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.port = this.port
      it.root = HelloMod()
    }
    return runServices([wisp])
  }
}

const class HelloMod : WebMod
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/plain; charset=utf-8"
    res.out.print("hello world #4")
  }
}