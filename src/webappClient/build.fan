#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

using build

**
** Build: webappClient
**
class Build : BuildPod
{

  override Void setup()
  {
    podName       = "webappClient"
    version       = globalVersion
    description   = "Client-side framework for building web applications"
    depends       = ["sys 1.0", "web 1.0", "webapp 1.0"]
    srcDirs       = [`fan/`, `test/`]
    includeSrc    = true
  }

  @target="compile fan source into pod"
  override Void compile(Bool full := false)
  {
    super.compile(full)
    doJavascript
  }

  private Void doJavascript()
  {
    log.info("javascript [$podName]")

    tempDir := scriptFile.parent + `temp-javascript/`
    tempDir.delete
    tempDir.create

    lib := tempDir.createFile("${podName}.js")
    out := lib.out

    // collect source files
    src := Str:File[:] { ordered = true }
    (scriptDir + `javascript/sys/`).walk  |f| { if (f.ext == "js") src[f.name] = f }
    (scriptDir + `javascript/fanx/`).walk |f| { if (f.ext == "js") src[f.name] = f }
    (scriptDir + `javascript/webappClient/`).walk |f| { if (f.ext == "js") src[f.name] = f }

    // output first
    first.each |Str name|
    {
      f := src[name]
      if (log.isDebug) log.printLine("  [$f]")
      if (f == null) throw Err("Required file not found: $name")
      append(f, out)
    }

    // output everyone else
    src.each |File f|
    {
      if (first.contains(f.name)) return
      if (last.contains(f.name)) return
      if (log.isDebug) log.printLine("  [$f]")
      append(f, out)
    }

    // output last
    last.each |Str name|
    {
      f := src[name]
      if (log.isDebug) log.printLine("  [$f]")
      if (f == null) throw Err("Required file not found: $name")
      append(f, out)
    }

    out.close

    // add into pod file
    jar := JdkTask.make(this).jarExe
    pod := Sys.homeDir + "lib/fan/${podName}.pod".toUri
    Exec.make(this, [jar.osPath, "fu", pod.osPath, "-C", tempDir.osPath, "."], tempDir).run

    tempDir.delete
  }

  private Void append(File f, OutStream out)
  {
    inBlock := false
    f.readAllLines.each |Str line|
    {
      s := line
      // line comments
      i := s.index("//")
      if (i != null) s = s[0..<i]
      // block comments
      temp := s
      a := temp.index("/*")
      if (a != null)
      {
        s = temp[0..<a]
        inBlock = true
      }
      if (inBlock)
      {
        b := temp.index("*/")
        if (b != null)
        {
          s = (a == null) ? temp[b+2..-1] : s + temp[b+2..-1]
          inBlock = false
        }
      }
      // trim and print
      s = s.trim
      if (inBlock) return
      if (s.size == 0) return
      out.printLine(s)
    }
  }

  // must be first
  Str[] first := ["Obj.js", "Pod.js", "Type.js", "Slot.js", "Err.js", "Func.js",
                  "Num.js", "List.js", "Map.js", "Enum.js", "Int.js", "InStream.js",
                  "OutStream.js"]

  // must be last
  Str[] last := ["sysPod.js", "webappClientPod.js"]


}