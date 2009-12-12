//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Nov 05  Brian Frank  Creation
//    3 Jun 06  Brian Frank  Ported from Java to Fantom - Megan's b-day!
//

**
** DefNode is the abstract base class for definition nodes such as TypeDef,
** MethodDef, and FieldDef.  All definitions may be documented using a
** Javadoc style FanDoc comment.
**
abstract class DefNode : Node
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Location location)
    : super(location)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  abstract CNamespace ns()

  Void walkFacets(Visitor v, VisitDepth depth)
  {
    if (facets != null && depth >= VisitDepth.expr)
    {
      facets.each |FacetDef f| { f.walk(v) }
    }
  }

  Obj? facet(Str qname, Obj? def)
  {
    // TODO: should we map these by qname?
    if (facets == null) return def
    f := facets.find |f| { f.key.qname == qname }
    if (f != null && f.val is LiteralExpr) return ((LiteralExpr)f.val).val
    return def
  }

  Bool hasMarkerFacet(Str qname)
  {
    if (facets == null) return false
    return facets.any |f| { f.key.qname == qname && f.val.id === ExprId.trueLiteral }
  }

  Void addFacet(CompilerSupport support, CSymbol symbol, Obj value)
  {
    if (facets == null) facets = FacetDef[,]
    loc := location
    f := FacetDef(SymbolExpr.makeFor(loc, symbol), Expr.makeForLiteral(loc, ns, value))
    facets.add(f)
  }

  Void printFacets(AstWriter out)
  {
    if (facets == null) return
    facets.each |FacetDef f| { f.print(out) }
  }

  virtual [Str:Str]? docMeta()
  {
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Str[]? doc          // lines of fandoc comment or null
  Int flags := 0      // type/slot/symbol flags
  FacetDef[]? facets  // facet declarations or null

}