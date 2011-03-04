#! /usr/bin/env fan
//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 May 10  Andy Frank  Creation
//

using compiler
using compilerJs
using gfx
using fwt
using util
using web
using webmod
using wisp

**
** Demo on how to mount a FWT widget tree anywere inside your DOM:
**  - Must specificy 'fwt.window.root' env var in WebUtil.jsMain
**  - Target element must be set to 'position:relative'
**  - Target element must have explicit size; either via CSS or
**    dynamically after page is loaded
**
class FwtMountDemo : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.port = this.port
      it.root = FwtMountDemoMod(homeDir)
    }
    return runServices([wisp])
  }
}

const class FwtMountDemoMod : WebMod
{
  new make(File dir) { scriptDir = dir }

  const File scriptDir

  override Void onGet()
  {
    name := req.modRel.path.first
    if (name == null) onIndex
    else if (name == "pod") onPodFile
    else res.sendErr(404)
  }

  Void onIndex()
  {
    // compile script
    js   := compile(scriptDir + `mount.fwt`)
    main := "mount::FwtMountDemoWin"
    env  := ["fwt.window.root":"fwt-root"]

    // write page
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("FWT Mount Demo").titleEnd
      .includeJs(`/pod/sys/sys.js`)
      .includeJs(`/pod/concurrent/concurrent.js`)
      .includeJs(`/pod/web/web.js`)
      .includeJs(`/pod/gfx/gfx.js`)
      .includeJs(`/pod/dom/dom.js`)
      .includeJs(`/pod/fwt/fwt.js`)
      .script.w(js).scriptEnd
      WebUtil.jsMain(out, main, env)
    out.headEnd
    out.body
      .h1.w("Fwt Mount Demo").h1End
      .p.w("This is normal HTML markup written from our WebMod").pEnd
      .div("id='fwt-root' style='position:relative; width:400px; height:300px;'").divEnd
      .p.w("And then some more HTML!").pEnd
    out.bodyEnd
    out.htmlEnd
  }

  Void onPodFile()
  {
    // serve up pod resources
    File file := ("fan://" + req.uri[1..-1]).toUri.get
    if (!file.exists) { res.sendErr(404); return }
    FileWeblet(file).onService
  }

  Str compile(File file)
  {
    input := CompilerInput.make
    input.podName   = file.basename
    input.summary   = ""
    input.version   = Version("0")
    input.log.level = LogLevel.err
    input.isScript  = true
    input.srcStr    = file.readAllStr
    input.srcStrLoc = Loc.makeFile(file)
    input.mode      = CompilerInputMode.str
    input.output    = CompilerOutputMode.js
    return Compiler(input).compile.js
  }
}

