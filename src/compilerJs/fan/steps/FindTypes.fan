//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    12 Jun 09  Andy Frank  Creation
//

using compiler

**
** FindTypes finds the types to actually compile. If the 'force'
** flag is set, all types are forced to be compiled.  Otherwise
** only types that have the '@javascript' facet set will be
** compiled.
**
class FindTypes : JsCompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(JsCompiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("FindTypes")

    // find types to compile
    compiler.toCompile = types.findAll |def|
    {
      if (compiler.force) return true
      if (def.facets?.get("javascript")?->toStr == "@javascript=true") return true
      return false
    }

    // find natives to compile
    if (compiler.nativeDirs != null)
    {
      compiler.natives = Str:File[:]
      compiler.nativeDirs.each |dir|
      {
        dir.listFiles.each |f| { compiler.natives[f.basename] = f }
      }
    }
  }

}

