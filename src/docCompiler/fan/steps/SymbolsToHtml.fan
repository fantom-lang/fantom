//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 09  Andy Frank  Creation
//

using compiler

**
** SymbolsToHtml generates the pod-meta.html file for a pod.
**
class SymbolsToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    echo("*** SYMBOLS NOT RUN ***")
    //log.debug("  Symbols [$compiler.pod]")
    //file := compiler.podOutDir + `pod-meta.html`
    //loc  := Loc("pod-meta.html")
    //SymbolsGenerator(compiler, loc, file.out).generate
  }

}