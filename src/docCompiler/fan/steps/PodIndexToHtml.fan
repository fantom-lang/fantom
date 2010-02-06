//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** PodIndexToHtml generates the Index.html file
** for a specific pod if one wasn't manually provided.
**
class PodIndexToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    index
    podDoc
  }

  Void index()
  {
    log.debug("  Index [$compiler.pod]")
    if (compiler.fandocIndex != null) return
    loc  := Loc("index.html")
    file := compiler.podOutDir + `index.html`
    PodIndexGenerator(compiler, loc, file.out).generate
  }

  Void podDoc()
  {
    log.debug("  PodDoc [$compiler.pod]")
    loc  := Loc("pod-doc.html")
    file := compiler.podOutDir + `pod-doc.html`
    PodDocGenerator(compiler, loc, file).generate
  }

}