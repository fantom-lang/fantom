//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 09  Andy Frank  Creation
//

using compiler

**
** SymbolsToHtml generates the symbols.html file for a pod.
**
class SymbolsToHtml : DocCompilerSupport
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    log.debug("  Symbols [$compiler.pod]")
    file := compiler.podDir + "symbols.html".toUri
    loc  := Location("symbols.html")
    SymbolsGenerator(compiler, loc, file.out).generate
  }

}