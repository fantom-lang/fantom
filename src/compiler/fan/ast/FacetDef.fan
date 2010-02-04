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

// TODO-FACET
  new makeOld(SymbolExpr key, Expr val)
    : super.make(key.loc)
  {
    this.key = key
    this.val = val
  }

  new make(Loc loc, CType type)
    : super(loc)
  {
    this.type = type
  }

//////////////////////////////////////////////////////////////////////////
// Serialization
//////////////////////////////////////////////////////////////////////////

  Str serialize()
  {
    if (names.isEmpty) return ""
    s := StrBuf()
    s.add(type.qname).addChar('{')
    names.each |n, i|
    {
      s.add(n).addChar('=').add(vals[i].serialize).addChar(';')
    }
    s.addChar('}')
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  Void walk(Visitor v)
  {
    if (key != null)
    {
      key = key.walk(v)
      val = val.walk(v)
    }
    else
    {
      vals = Expr.walkExprs(v, vals)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Str toStr()
  {
if (key != null) return "$key=$val"
    return "@$type"
  }

  override Void print(AstWriter out) { out.w(key).w("=").w(val).nl }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  CType? type
  Str[] names := Str[,]
  Expr[] vals := Expr[,]

  SymbolExpr? key   // TODO-FACET
  Expr? val         // TODO-FACET

}