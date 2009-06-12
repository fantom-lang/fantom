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
    this.c = compiler
  }

//////////////////////////////////////////////////////////////////////////
// Convenience
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the compiler.
  **
  virtual Compiler compiler() { c }

  **
  ** Convenience for compiler.ns
  **
  CNamespace ns()
  {
    return c.ns
  }

  **
  ** Convenience for compiler.pod
  **
  PodDef pod()
  {
    return c.pod
  }

  **
  ** Convenience for compiler.pod.units
  **
  CompilationUnit[] units()
  {
    return c.pod.units
  }

  **
  ** Convenience for compiler.types
  **
  TypeDef[] types()
  {
    return c.types
  }

  **
  ** Convenience for compiler.log
  **
  CompilerLog log()
  {
    return c.log
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
    c.types.add(t)
  }

  **
  ** Remove a synthetic type
  **
  Void removeTypeDef(TypeDef t)
  {
    t.unit.types.removeSame(t)
    pod.typeDefs.remove(t.name)
    c.types.removeSame(t)
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
    c.log.compilerErr(e)
    c.errors.add(e)
    return e
  }

  **
  ** If any errors are accumulated, then throw the first one
  **
  Void bombIfErr()
  {
    if (!c.errors.isEmpty)
      throw c.errors.first
  }

  **
  ** Convenience for `sys::Type.findByFacet` which disables
  ** all the warnings which might spew out while rebuilding
  ** the type database in the middle of a compile.
  **
  static Type[] findByFacet(Str facetName, Obj facetVal, Obj? options := null)
  {
    log := Log.get("typedb")
    oldLevel := log.level
    log.level = LogLevel.error
    try
      return Type.findByFacet(facetName, facetVal, options)
    finally
      log.level = oldLevel
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Compiler c           // parent compiler instance
  Bool suppressErr := false    // throw SuppressedErr instead of CompilerErr

}

**************************************************************************
** SuppressedErr
**************************************************************************

internal const class SuppressedErr : Err
{
  new make() : super(null, null) {}
}