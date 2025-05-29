//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jul 06  Brian Frank  Creation
//

**
** ParamDef models the definition of a method parameter.
**
class ParamDef : Node, CParam
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Loc loc, CType type, Str name, Expr? def := null)
    : super(loc)
  {
    this.type = type
    this.name = name
    this.def  = def
  }

//////////////////////////////////////////////////////////////////////////
// CParam
//////////////////////////////////////////////////////////////////////////

  override Bool hasDefault() { def != null }

  ** Does this param have a def that uses an assign store instruction
  ** because CheckParamDefs detected it used previous parameters
  Bool isAssign() { def != null && def.id === ExprId.assign }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Str toStr()
  {
    return "$type $name"
  }

  override Void print(AstWriter out)
  {
    out.w(type).w(" ").w(name)
    if (def != null) { out.w(" := "); def.print(out) }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override CType type        // type of parameter
  override Str name          // local variable name
  Expr? def                  // default expression

}

