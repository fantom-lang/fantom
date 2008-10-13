//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Nov 05  Brian Frank  Creation
//    3 Jun 06  Brian Frank  Ported from Java to Fan - Megan's b-day!
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
// Tree
//////////////////////////////////////////////////////////////////////////

  abstract CNamespace ns()

  Void walkFacets(Visitor v, VisitDepth depth)
  {
    if (facets != null && depth >= VisitDepth.expr)
    {
      facets.each |FacetDef f| { f.walk(v) }
    }
  }

  Void addFacet(CompilerSupport support, Str name, Obj value)
  {
    if (facets == null) facets = Str:FacetDef[:]
    f := FacetDef.make(location, name, LiteralExpr.makeFor(location, ns, value))

    dup := facets[name]
    if (dup != null)
      support.err("Facet '$name' conflicts with auto-generated facet", dup.location)
    else
      facets.add(name, f)
  }

  Void printFacets(AstWriter out)
  {
    if (facets == null) return
    facets.each |FacetDef f| { f.print(out) }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Str[]? doc              // lines of fandoc comment or null
  Int flags := 0          // type/slot flags
  [Str:FacetDef]? facets  // facet declarations (may be null)

}