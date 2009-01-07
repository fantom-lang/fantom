#! /usr/bin/env fansubstitute
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Dec 08  Andy Frank  Creation
//

using build

**
** Build: jsfan
**
class Build : BuildScript
{

  override Target defaultTarget()
  {
    return target("zip")
  }

  @target="assemble Javascript into sys.js"
  Void zip()
  {
    libJsDir := devHomeDir + `lib/javascript/`
    src := (scriptDir + `js/`).listFiles
    out := libJsDir.createFile("sys.js").out

    order.each |Str name|
    {
      f := src.find |File f->Bool| { return f.name == name }
      if (f == null) throw Err("$name not found")
      append(f, out)
    }

    src.each |File f|
    {
      if (order.contains(f.name)) return
      append(f, out)
    }
    out.close
  }

  private Void append(File f, OutStream out)
  {
    block := false
    f.readAllLines.each |Str line|
    {
      s := line.trim
      if (s.size == 0) return
      if (s.startsWith("//")) return
      if (s.startsWith("/*")) { block = true; return }
      if (s.startsWith("*/")) { block = false; return }
      if (block) return
      out.printLine(line)
    }
  }

  Str[] order := ["Sys.js", "Obj.js", "Type.js", "Num.js"]

}