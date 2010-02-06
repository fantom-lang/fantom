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

  new make(Loc loc)
    : super(loc)
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

  CFacet? facet(Str qname)
  {
    if (facets == null) return null
    return facets.find |f| { f.type.qname == qname }
  }

  Void addFacet(CompilerSupport support, CType type, [Str:Obj]? vals := null)
  {
    if (facets == null) facets = FacetDef[,]
    loc := this.loc
    f := FacetDef(loc, type)
    vals?.each |v, n|
    {
      f.names.add(n)
      f.vals.add(Expr.makeForLiteral(loc, ns, v))
    }
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
  Int flags := 0      // type/slot flags
  FacetDef[]? facets  // facet declarations or null

}