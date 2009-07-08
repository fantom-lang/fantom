#! /usr/bin/env fansubstitute
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using build

class Build : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="compile javascript for sys pod"
  Void compile()
  {
    log.info("compile [js]")

    tempDir := scriptFile.parent + `temp-js/`
    tempDir.delete
    tempDir.create

    lib := tempDir.createFile("sys.js")
    out := lib.out

    // collect source files
    src := Str:File[:] { ordered = true }
    (scriptFile.parent + `fan/`).walk  |f| { if (f.ext == "js") src[f.name] = f }
    (scriptFile.parent + `fanx/`).walk |f| { if (f.ext == "js") src[f.name] = f }

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
    pod := devHomeDir + `lib/fan/sys.pod`
    Exec.make(this, [jar.osPath, "fu", pod.osPath, "-C", tempDir.osPath, "."], tempDir).run

    tempDir.delete
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="delete all intermediate and target files"
  Void clean()
  {
    log.info("clean [js]")
    Delete.make(this, scriptFile.parent + `temp-js/`).run
  }

//////////////////////////////////////////////////////////////////////////
// CompileAll
//////////////////////////////////////////////////////////////////////////

  @target="alias for compile"
  Void compileAll()
  {
    compile
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @target="clean+compile"
  Void full()
  {
    clean
    compile
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  Void append(File f, OutStream out)
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

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // must be first
  Str[] first := ["Obj.js", "Pod.js", "Type.js", "Slot.js", "Err.js", "Func.js",
                  "Num.js", "List.js", "Map.js", "Enum.js", "Long.js", "Int.js",
                  "InStream.js", "OutStream.js"]

  // must be last
  Str[] last := ["sysPod.js", "timezones.js"]

}