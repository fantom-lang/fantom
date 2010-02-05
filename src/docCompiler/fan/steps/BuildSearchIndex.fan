//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** BuildSearchIndex generates the top level navigation and search index.
**
class BuildSearchIndex : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    log.debug("  BuildSearchIndex")
    file := compiler.outDir + "searchIndex.js".toUri
    out  := file.out
    out.print("var searchIndex = [\n")
    first := true
    Pod.list.each |Pod p|
    {
      if (p.meta["pod.docApi"] == "false") return
      p.types.each |Type t, Int i|
      {
        if (!showType(t)) return
        if (first) first = false
        else out.print(",\n")
        out.print("\"$t.qname\"")
      }
    }
    out.print("];\n")
    out.close
  }

}