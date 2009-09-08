//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 May 07  Andy Frank  Creation
//

using compiler

**
** SourceToHtml generates a HTML file for each type in pod
**
class SourceToHtml : DocCompilerSupport
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    compiler.pod.types.each |Type t|
    {
      if (!HtmlGenerator.showType(t)) return
      generate(t)
    }
  }

  Void generate(Type t)
  {
    srcFileFacet := t->sourceFile
    srcFile := t.pod.files["/src/$srcFileFacet".toUri]
    if (srcFile == null) return

    log.debug("  Source [$t]")
    file := compiler.podDir + "${t.name}_src.html".toUri
    loc := Location("Source $t.qname")

    SourceToHtmlGenerator(compiler, loc, file.out, t, srcFile).generate
  }
}