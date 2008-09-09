//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** PodIndexToHtml generates the Index.html file
** for a specific pod if one wasn't manually provided.
**
class PodIndexToHtml : DocCompilerSupport
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    log.debug("  Index [$compiler.pod]")
    if (compiler.fandocIndex != null) return
    file := compiler.podDir + "index.html".toUri
    loc  := Location("index.html")
    PodIndexGenerator(compiler, loc, file.out).generate
  }

}
