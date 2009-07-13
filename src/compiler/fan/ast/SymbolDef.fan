//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

**
** SymbolDef
**
class SymbolDef : DefNode
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CNamespace ns, Location location, CType? of, Str name, Expr val)
    : super(location)
  {
    this.ns   = ns
    this.of   = of
    this.name = name
    this.val  = val
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  override Str toStr()
  {
    s := StrBuf()
    if (of != null) s.add(of).addChar(' ')
    s.add(name).add(" := ").add(val)
    return s.toStr
  }

  Void walk(Visitor v, VisitDepth depth)
  {
    v.enterSymbolDef(this)
    if (depth >= VisitDepth.expr) val = val.walk(v)
    v.exitSymbolDef(this)
  }

  override Void print(AstWriter out)
  {
    out.w(toStr).nl
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly CNamespace ns  // compiler's namespace
  CType? of
  Str name
  Expr val

}