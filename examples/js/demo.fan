#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//

using util
using web
using webmod
using wisp
using compiler
using compilerJs

class JsDemo : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    wisp := WispService
    {
      it.port = this.port
      it.root = JsDemoMod(homeDir)
    }
    return runServices([wisp])
  }
}

const class JsDemoMod : WebMod
{
  new make(File dir) { scriptDir = dir }

  const File scriptDir

  override Void onGet()
  {
    name := req.modRel.path.first
    if (name == null)
      onIndex
    else if (name == "pod")
      onPodFile
    else if (name == "echo")
      onEcho
    else
      ShowScript(scriptDir + `$name`).onGet
  }

  override Void onPost()
  {
    name := req.modRel.path.first
    if (name == "echo") onEcho
    else super.onPost
  }

  Void onIndex()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      out.title.w("FWT Demo").titleEnd
    out.headEnd
    out.body
      out.h1.w("FWT Demo").h1End
      out.ul
      scriptDir.list.each |f|
      {
        if (f.ext == "fwt")
          out.li.a(`/$f.name`).w(f.name).aEnd.liEnd
      }
      out.ulEnd
    out.bodyEnd
    out.htmlEnd
  }

  Void onEcho()
  {
    c := req.method == "GET" ? "" : req.in.readAllStr
    s := "$req.method $req.uri
          $req.headers
          $c"
    buf := Buf().printLine(s)
    res.headers["Content-Length"] = buf.size.toStr
    res.headers["Content-Type"] = "text/plain"
    res.out.writeBuf(buf.flip)
  }

  Void onPodFile()
  {
    // serve up pod resources
    File file := ("fan://" + req.uri[1..-1]).toUri.get
    if (!file.exists) { res.sendErr(404); return }
    FileWeblet(file).onService
  }
}

class ShowScript : Weblet
{
  new make(File f) { file = f }
  override Void onGet()
  {
    if (!file.exists) { res.sendErr(404); return }

    // compile script into js
    compile
    main := compiler.types[0].qname

    // write page
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      out.title.w("FWT Demo - $file.name").titleEnd
      out.includeJs(`/pod/sys/sys.js`)
      out.includeJs(`/pod/concurrent/concurrent.js`)
      out.includeJs(`/pod/web/web.js`)
      out.includeJs(`/pod/gfx/gfx.js`)
      out.includeJs(`/pod/dom/dom.js`)
      out.includeJs(`/pod/fwt/fwt.js`)
      out.style.w(
       "body { font: 10pt Arial; }
        a { color: #00f; }
        ").styleEnd
      out.script.w(js).scriptEnd
      WebUtil.jsMain(out, main)
    out.headEnd
    out.body
    out.bodyEnd
    out.htmlEnd
  }

  Void compile()
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

    this.compiler = Compiler(input)
    this.js = compiler.compile.js
  }

  File file
  Compiler? compiler
  Str? js
}

