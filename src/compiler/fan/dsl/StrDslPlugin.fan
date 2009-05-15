//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 09  Brian Frank  Creation
//

**
** StrDslPlugin is used to create a raw Str literal.
**
@compilerDsl="sys::Str"
class StrDslPlugin : DslPlugin
{

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
  override Expr compile(DslExpr dsl)
  {
    return LiteralExpr.makeFor(dsl.location, ns, dsl.src)
  }

}