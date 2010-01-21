//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** TopIndexToHtml generates the top level navigation and search index.
**
class TopIndexToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    log.debug("  TopIndexToHtml")
    compiler.outDir.create
    file := compiler.outDir + "index.html".toUri
    loc  := Loc("index.html")
    TopIndexGenerator(compiler, loc, file.out).generate
  }

}