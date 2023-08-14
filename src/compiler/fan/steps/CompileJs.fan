//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 09  Brian Frank  Creation
//

**
** CompileJs is used to call the compilerJs plugin to generate
** javascript for the pod if the @js facet is configured.
**
class CompileJs  : CompilerStep
{

  new make(Compiler compiler) : super(compiler) {}

  override Void run()
  {
    if (needCompileJs)
    {
      log.info("CompileJs")
      compile("compilerJs::CompileJsPlugin")
      compile("compilerEs::CompileEsPlugin")
    }

    // generate d.ts files when forcing js
    if (compiler.input.forceJs || pod.name == "sys") compile("nodeJs::CompileTsPlugin")
  }

  private Void compile(Str qname)
  {
    // try to resolve plugin
    t := Type.find(qname, false)
    if (t == null)
    {
      log.info("WARN: ${qname} not installed")
      return
    }

    // do it!
    t.make([compiler])->run
  }

  Bool needCompileJs()
  {
    // in JS mode we force JS compilation
    if (compiler.input.output === CompilerOutputMode.js) return true

    // if any JS directories were specified force JS compilation
    if (compiler.jsFiles != null && !compiler.jsFiles.isEmpty) return true

    // are we forcing generation of js for all types
    if (compiler.input.forceJs) return true

    // run JS compiler if any type has @Js facet
    return compiler.types.any { it.hasFacet("sys::Js") }
  }

}