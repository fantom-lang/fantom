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
mixin DocCompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Convenience
//////////////////////////////////////////////////////////////////////////

  **
  ** Parent compiler instance
  **
  abstract DocCompiler compiler()

  **
  ** Convenience for compiler.log
  **
  CompilerLog log() { compiler.log }

  **
  ** Return if we should be generating source code documentation.
  **
  Bool docsrc() { compiler.pod.facet(@docsrc, false) == true }

//////////////////////////////////////////////////////////////////////////
// Filters
//////////////////////////////////////////////////////////////////////////

  Bool showType(Type t)
  {
    if (t.isInternal) return false
    if (t.isSynthetic) return false
    if (t.fits(Test#) && t != Test#) return false
    if (t.facet(@nodoc) == true) return false
    return true
  }

  Bool showSlot(Type t, Slot s)
  {
    if (s.isSynthetic) return false
    if (s.facet(@nodoc) == true) return false
    return t == s.parent
  }

  Bool showByDefault(Type t, Slot s)
  {
    v := s.isPublic || s.isProtected
    v &= t == Obj# || s.parent != Obj#
    v &= t == s.parent
    return v
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
  ** Create, log, and return a warning CompilerErr.
  **
  CompilerErr warn(Str msg, Location loc)
  {
    return errReport(CompilerErr(msg, loc, null, LogLevel.warn))
  }

  **
  ** Log, store, and return the specified CompilerErr.
  **
  CompilerErr errReport(CompilerErr e)
  {
    compiler.log.compilerErr(e)
    if (e.isWarn)
      compiler.warns.add(e)
    else
      compiler.errs.add(e)
    return e
  }

  **
  ** If any errors are accumulated, then throw the last one
  **
  Void bombIfErr()
  {
    if (!compiler.errs.isEmpty)
      throw compiler.errs.last
  }

}