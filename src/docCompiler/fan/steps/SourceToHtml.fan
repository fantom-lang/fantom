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
class SourceToHtml : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    // check if @docsrc pod facet configured
    if (!docsrc) return

    // make sure srcDir is configured
    if (compiler.srcDir == null)
    {
      warn("DocCompiler.srcDir not configured!", Loc("config"))
      return
    }

    // walk the src tree looking for fan files
    srcFiles := Str:File[:]
    compiler.srcDir.walk |f|
    {
      if (f.isDir || f.ext != "fan") return
      if (f.name == "build.fan") return
      if (srcFiles.containsKey(f.name))
        warn("Duplicate source file names: $f.name", Loc.makeFile(f))
      else
        srcFiles[f.name] = f
    }

    // generate a file for each type
    compiler.pod.types.each |Type t|
    {
      generate(srcFiles, t)
    }
  }

  private Void generate(Str:File srcFiles, Type t)
  {
    // skip non-public types and such
    if (!showType(t)) return

    // get file name
    srcFileName := (Str)t->sourceFile
    srcFile := srcFiles[srcFileName]
    if (srcFile == null)
    {
      warn("Cannot find source file: $srcFileName", Loc(srcFileName))
      return
    }

    // do it
    log.debug("  Source [$t]")
    file := compiler.podOutDir + `${t.name}_src.html`
    loc := Loc("Source $t.qname")
    SourceToHtmlGenerator(compiler, loc, file.out, t, srcFile).generate
  }

}