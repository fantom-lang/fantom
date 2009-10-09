#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//

using fand
using web
using webapp
using wisp
using compiler
using compilerJs

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
    UriSpace.root.create(`/homePage`, Home#)
    UriSpace.root.create(`/show-script`, ShowScript#)
    UriSpace.root.create(`/echo`, EchoWeblet#)
  }
}

class Home : Widget
{
  File scriptDir := File(type->sourceFile->toUri->parent)
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/html"
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
          out.li.a(`/show-script?$f.name`).w(f.name).aEnd.liEnd
      }
      out.ulEnd
    out.bodyEnd
    out.htmlEnd
  }
}

class ShowScript : Widget
{
  File scriptDir := File(type->sourceFile->toUri->parent)
  override Void onGet()
  {
    f := scriptDir + req.uri.queryStr.toUri
    if (!f.exists) { res.sendError(404); return }

    compile(f)
    t := compiler.types[0]
    entryPoint := "fan.${t.pod}.${t.name}"

    res.headers["Content-Type"] = "text/html"
    out := res.out
    out.docType
    out.html
    out.head
      out.title.w("FWT Demo - $f.name").titleEnd
      out.includeJs(`/sys/pod/sys/sys.js`)
      out.includeJs(`/sys/pod/dom/dom.js`)
      out.includeJs(`/sys/pod/gfx/gfx.js`)
      out.includeJs(`/sys/pod/fwt/fwt.js`)
      out.style.w(
       "body { font: 10pt Arial; }
        a { color: #00f; }
        ").styleEnd
      out.script.w(js).w(
       "var hasRun = false;
        var shell  = null;
        var doLoad = function()
        {
          // safari appears to have a problem calling this event
          // twice, so make sure we short-circuit if already run
          if (hasRun) return;
          hasRun = true;

          // load fresco
          shell = ${entryPoint}.make();
          shell.open();
        }
        var doResize = function() { shell.relayout(); }
        if (window.addEventListener)
        {
          window.addEventListener('load', doLoad, false);
          window.addEventListener('resize', doResize, false);
        }
        else
        {
          window.attachEvent('onload', doLoad);
          window.attachEvent('onresize', doResize);
        }
        ").scriptEnd
    out.headEnd
    out.body
    out.bodyEnd
    out.htmlEnd
  }

  Void compile(File file)
  {
    input := CompilerInput.make
    input.podName        = file.basename
    input.version        = Version("0")
    input.log.level      = LogLevel.error
    input.isScript       = true
    input.srcStr         = file.readAllStr
    input.srcStrLocation = Location.makeFile(file)
    input.mode           = CompilerInputMode.str
    input.output         = CompilerOutputMode.str
    this.compiler = JsCompiler(input)
    this.js = compiler.compile.str
  }

  JsCompiler? compiler
  Str? js
}

class EchoWeblet : Weblet
{
  override Void onGet()  { print(req.uri.queryStr)  }
  override Void onPost() { print(req.in.readAllStr) }
  Void print(Str s)
  {
    buf := Buf().printLine(s)
    res.headers["Content-Length"] = buf.size.toStr
    res.headers["Content-Type"] = "text/plain"
    res.out.writeBuf(buf.flip)
  }
}