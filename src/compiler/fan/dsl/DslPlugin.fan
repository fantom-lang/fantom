//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 09  Brian Frank  Creation
//

**
** DslPlugin is the base class for Domain Specific Language
** plugins used to compile embedded DSLs.  Subclasses are registered
** on the anchor type's qname with the "compilerDsl" facet and must
** declare a constructor with a Compiler arg.
**
abstract class DslPlugin : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Find a DSL plugin for the given anchor type.  If there
  ** is a problem then log an error and return null.
  **
  static DslPlugin? find(CompilerSupport c, Location loc, CType anchorType)
  {
    qname := anchorType.qname
    t := Type.findByFacet("compilerDsl", qname)

    if (t.size > 1)
    {
      c.err("Multiple DSL plugins registered for '$qname': $t", loc)
      return null
    }

    if (t.size == 0)
    {
      c.err("No DSL plugin is registered for '$qname'", loc)
      return null
    }

    try
    {
      return t.first.make([c.compiler])
    }
    catch (Err e)
    {
      e.trace
      c.errReport(CompilerErr("Cannot construct DSL plugin '$t.first'", loc, e))
      return null
    }
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor with associated compiler.
  **
  new make(Compiler c) : super(c) {}

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile DSL source into its Fan equivalent expression.
  **
  abstract Expr compile(DslExpr dsl)

}