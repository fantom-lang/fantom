//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** ApiToHtml generates an HTML file for each type in pod
**
class ApiToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    compiler.pod.types.each |Type t|
    {
      if (!showType(t)) return
      generate(t)
    }
  }

  Void generate(Type t)
  {
    log.debug("  API [$t]")
    file := compiler.podOutDir + "${t.name}.html".toUri
    loc := Loc(t.qname)
    compiler.curType = t
    ApiToHtmlGenerator(compiler, loc, file.out, t).generate
    compiler.curType = null
  }
}