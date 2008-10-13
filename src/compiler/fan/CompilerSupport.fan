//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 06  Brian Frank  Creation
//

**
** CompilerSupport provides lots of convenience methods for classes
** used during the compiler pipeline.
**
class CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(Compiler compiler)
  {
    this.compiler = compiler
  }

//////////////////////////////////////////////////////////////////////////
// Convenience
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for compiler.ns
  **
  CNamespace ns()
  {
    return compiler.ns
  }

  **
  ** Convenience for compiler.pod
  **
  PodDef pod()
  {
    return compiler.pod
  }

  **
  ** Convenience for compiler.pod.units
  **
  CompilationUnit[] units()
  {
    return compiler.pod.units
  }

  **
  ** Convenience for compiler.types
  **
  TypeDef[] types()
  {
    return compiler.types
  }

  **
  ** Convenience for compiler.log
  **
  CompilerLog log()
  {
    return compiler.log
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Add a synthetic type
  **
  Void addTypeDef(TypeDef t)
  {
    t.unit.types.add(t)
    pod.typeDefs[t.name] = t
    compiler.types.add(t)
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  **
  ** Create, log, and return a CompilerErr.
  **
  virtual CompilerErr err(Str msg, Location? loc)
  {
    if (suppressErr) throw SuppressedErr.make
    return errReport(CompilerErr.make(msg, loc))
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
  ** If any errors are accumulated, then throw the first one
  **
  Void bombIfErr()
  {
    if (!compiler.errors.isEmpty)
      throw compiler.errors.first
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Compiler compiler            // parent compiler instance
  Bool suppressErr := false    // throw SuppressedErr instead of CompilerErr

}

**************************************************************************
** SuppressedErr
**************************************************************************

internal const class SuppressedErr : Err
{
  new make() : super(null, null) {}
}