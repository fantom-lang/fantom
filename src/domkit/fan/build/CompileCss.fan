//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Sep 2017  Andy Frank  Creation
//

**
** CompileCss compiles the DomKit source CSS into a single merged CSS
** document.
**
class CompileCss
{
  ** Compile domkit css into single merged CSS file at the given
  ** OutStream.  If 'close' is 'true', the stream is closed.
  Void compile(OutStream out, Bool close := true)
  {
    // collect source css
    pod := Pod.find("domkit")
    src := pod.files.findAll |f| { f.ext == "css" }
    src.sort |a,b| { a.name.localeCompare(b.name) }

    // make sure Base.css is first
    base := src.find |f| { f.name == "Base.css" }
    src.moveTo(base, 0)

    // merge css output
    src.each |f|
    {
      f.eachLine |line|
      {
        trim := line.trim
        if (trim.isEmpty || trim.startsWith("//")) return
        out.printLine(line)
      }
      out.printLine("").flush
    }

    if (close) out.sync.close
  }
}