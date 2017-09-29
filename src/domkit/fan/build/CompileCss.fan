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
  ** If 'true' add CSS so that the <body> tag fills the viewport 100%.
  Bool fullscreen := false

  ** Compile domkit css into single merged CSS file at the given
  ** OutStream.  If 'close' is 'true', the stream is closed.
  Void compile(OutStream out, Bool close := true)
  {
    // TODO: temp until we move this out; @import must be first rule
    out.printLine("@import url(https://fonts.googleapis.com/css?family=Roboto:300,400,500,700);")
    out.printLine("@import url(https://fonts.googleapis.com/css?family=Roboto+Mono);")

    // process opts
    if (fullscreen)
    {
      out.printLine("html{height:100%;}")
      out.printLine("body{height:100%;overflow:hidden;}")
    }

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