//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Aug 07  Brian Frank  Creation
//

**
** FacetDef models a facet declaration.
**
class FacetDef : Node
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(SymbolExpr key, Expr val)
    : super(key.location)
  {
    this.key = key
    this.val = val
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  Void walk(Visitor v)
  {
    key = key.walk(v)
    val = val.walk(v)
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Str toStr() { "$key=$val" }

  override Void print(AstWriter out) { out.w(key).w("=").w(val).nl }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  SymbolExpr key
  Expr val

}