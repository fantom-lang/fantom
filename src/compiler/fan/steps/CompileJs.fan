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

  new make(Compiler compiler) : super(compiler)
  {
    this.hasJs = compiler.types.any { it.hasFacet("sys::Js") }
  }

  ** Is any type annotated with @Js
  private const Bool hasJs

  override Void run()
  {
    log.info("CompileJs")
    if (needCompileJs)
    {
      compile("compilerJs::CompileJsPlugin")
    }

    if (needCompileEs)
    {
      if (pod.name != "sys") compile("compilerEs::CompileEsPlugin")
      genTsDecl
    }
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

  private Void genTsDecl()
  {
    // find the tool to generate d.ts
    t := Type.find("nodeJs::GenTsDecl", false)
    if (t == null)
    {
      log.info("WARN: GenTsDecl not available")
      return
    }

    // run it
    buf := Buf()
    t.make([buf.out, pod, compiler.input.forceJs || compiler.isSys])->run
    if (!buf.isEmpty)
    {
      compiler.tsDecl = buf.seek(0).readAllStr
    }
  }

  Bool needCompileEs()
  {
    needCompileJs || compiler.isSys
  }

  Bool needCompileJs()
  {
    // in JS mode we force JS compilation
    if (compiler.input.output === CompilerOutputMode.js) return true

    // if any JS directories were specified force JS compilation
    if (compiler.jsFiles != null && !compiler.jsFiles.isEmpty) return true

    // are we forcing generation of js for all types
    if (compiler.input.forceJs) return true

    // are there any props files that need to be written to JS?
    if (compiler.jsPropsFiles != null && !compiler.jsPropsFiles.isEmpty) return true

    // run JS compiler if any type has @Js facet
    return this.hasJs
  }

}

