//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** DocCompilerSupport provides lots of convenience methods
** for classes used during the documentation compiler pipeline.
**
class DocCompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(DocCompiler compiler)
  {
    this.compiler = compiler
  }

//////////////////////////////////////////////////////////////////////////
// Convenience
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for compiler.log
  **
  CompilerLog log()
  {
    return compiler.log
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  **
  ** Create, log, and return a CompilerErr.
  **
  virtual CompilerErr err(Str msg, Location loc)
  {
    return errReport(CompilerErr(msg, loc))
  }

  **
  ** Log, store, and return the specified CompilerErr.
  **
  CompilerErr errReport(CompilerErr e)
  {
    compiler.log.compilerErr(e)
    compiler.errors.add(e)
    return e
  }

  **
  ** If any errors are accumulated, then throw the last one
  **
  Void bombIfErr()
  {
    if (!compiler.errors.isEmpty)
      throw compiler.errors.last
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  DocCompiler compiler

}