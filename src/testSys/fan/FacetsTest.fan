//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jul 06 - Fireworks!  Brian Frank  Creation
//

**
** FacetsTests
**
class FacetsTest : Test
{
  Str? aField
  Void aMethod() {}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void testAttributes()
  {
    verifyEq(typeof->lineNumber, 12)
    verifyEq(typeof->sourceFile, "FacetsTest.fan")

    Field field := #aField
    verifyEq(field->lineNumber, 14)

    Method method := #aMethod
    verifyEq(method->lineNumber, 15)
  }

//////////////////////////////////////////////////////////////////////////
// Empty Facets
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    verifyEq(FacetsTest#.facets, Facet[,])
    verifyEq(FacetsTest#.facets.isImmutable, true)
    verifyEq(FacetsTest#.facet(NoDoc#, false), null)

    verifyEq(FacetsTest#testEmpty.facets, Facet[,])
    verifyEq(FacetsTest#testEmpty.facets.isImmutable, true)
    verifyEq(FacetsTest#testEmpty.facet(NoDoc#, false), null)
  }

//////////////////////////////////////////////////////////////////////////
// Type Facets
//////////////////////////////////////////////////////////////////////////

  Void testTypeFacets()
  {
    t := FacetsA#
    verifyFacets(t, t.facets)
  }

  Void testSlotFacets()
  {
    s := FacetsA#i
    verifyFacets(s, s.facets)
  }

  Void verifyFacets(Obj t, Facet[] facets)
  {
    verifyEq(facets.isImmutable, true)
    verifyEq(facets.typeof, Facet[]#)
    verifyEq(facets.size, 3)

    verifyEq(t->facet(Transient#, false), null)
    verifyErr(UnknownFacetErr#) { t->facet(Transient#) }
    verifyErr(UnknownFacetErr#) { t->facet(Transient#, true) }

    m1 := (FacetM1)t->facet(FacetM1#)
    s1 := (FacetS1)t->facet(FacetS1#)
    s2 := (FacetS2)t->facet(FacetS2#)

    verifySame(m1, FacetM1.defVal)
    verifyEq(s1.val, "foo")
    verifyEq(s2.b, false)
    verifyEq(s2.i, 77)
    verifyEq(s2.s, null)
    verifyEq(s2.v, Version("9.0"))
    verifyEq(s2.l, [1, 2, 3])
    verifySame(s2.type, Str#)
    verifySame(s2.slot, Float#nan)
    verify(facets.contains(m1))
    verify(facets.contains(s1))
    verify(facets.contains(s2))
    verifySame(facets, t->facets)
  }

}

**************************************************************************
** FacetsA
**************************************************************************

@FacetM1
@FacetS1 { val = "foo" }
@FacetS2 { i = 77; v = Version("9.0"); l = [1, 2, 3]; type = Str#; slot = Float#nan }
class FacetsA
{
  @FacetM1
  @FacetS1 { val = "foo" }
  @FacetS2 { i = 77; v = Version("9.0"); l = [1, 2, 3]; type = Str#; slot = Float#nan }
  Int i
}