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
// TODO-FACET
return
// skip pods if @js facet not configured or outpout mode not js
//
//if (!pod.hasMarkerFacet("sys::js") &&
//        compiler.input.output !== CompilerOutputMode.js) return
//

    // try to resolve plugin type
    t := Type.find("compilerJs::CompileJsPlugin", false)
    if (t == null)
    {
      log.info("WARN: compilerJs not installed!")
      return
    }

    // do it!
    log.info("CompileJs")
    t.make([compiler])->run
  }

}