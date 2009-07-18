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
@testSysByStr=["alpha"]
@testSysByType=[SerA#]
class FacetsTest : Test
{
  Str? aField
  Void aMethod() {}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void testAttributes()
  {
    verifyEq(type->lineNumber, 14)
    verifyEq(type->sourceFile, "FacetsTest.fan")

    Field field := #aField
    verifyEq(field->lineNumber, 16)

    Method method := #aMethod
    verifyEq(method->lineNumber, 17)
  }

//////////////////////////////////////////////////////////////////////////
// Type Facets
//////////////////////////////////////////////////////////////////////////

  Void testTypeFacetsA()
  {
    t := FacetsA#
    verifyEq(t.facets.isRO, true)
    verifyEq(t.facets.type, [Symbol:Obj?]#)
    verifyEq(t.facets.size, 16)
    verifyEq(t.facet(@transient), null)
    verifyEq(t.facet(@transient, "!"), "!")
    verifyErr(ReadonlyErr#) |,| { t.facets.set(@transient, "!") }

    verifyTypeFacet(t, @boolA, true)
    verifyTypeFacet(t, @boolB, false)
    verifyTypeFacet(t, @intA, 'c')
    verifyTypeFacet(t, @strA, "a\tb\nc\u0abc!")
    verifyTypeFacet(t, @floatA, 2.4f)
    verifyTypeFacet(t, @durA, 3min)
    verifyTypeFacet(t, @uriA, `foo.txt`)
    verifyTypeFacet(t, @verA, Version.fromStr("2.3"))
    verifyTypeFacet(t, @listA, Str[,])
    verifyTypeFacet(t, @listB, [1, 2, 3])
    verifyTypeFacet(t, @mapA, [2:"two", 3:"three"])
    verifyTypeFacet(t, @floatB, Float.nan)
    verifyTypeFacet(t, @floatC, Float.posInf)
    verifyTypeFacet(t, @floatD, Float.negInf)
    verifyTypeFacet(t, @monA, Month.jun)

    t.facets.keys.each { verifySame(t.facet(it), t.facet(it)) }
  }

  Void testTypeFacetsB()
  {
    t := FacetsB#

    verifyTypeFacet(t, @serialC, FacetsA {i=2; f=3f; s="gunslinger"})
    verifyTypeFacet(t, @listD, [false, Version("8"), FacetsA {s="tull"}])
    verifyTypeFacet(t, @listA, ["man", "in", "black"])

    verifyNotSame(t.facet(@serialC), t.facet(@serialC))
    verifyNotSame(t.facet(@listD), t.facet(@listD))
    verifySame(t.facet(@listA), t.facet(@listA))
    verifyNotSame(t.facets, t.facets)
  }

  Void verifyTypeFacet(Type t, Symbol key, Obj expected)
  {
    verifyEq(t.facet(key), expected)
    verifyEq(t.facet(key, "!@#"), expected)
    verifyEq(t.facets[key], expected)
  }

//////////////////////////////////////////////////////////////////////////
// Slot Facets
//////////////////////////////////////////////////////////////////////////

  Void testSlotFacets1()
  {
    f := FacetsA#.field("i")
    verifyEq(f.facets.isRO, true)
    verifyEq(f.facets.size, 3)
    verifyEq(f.facets.type, [Symbol:Obj?]#)
    verifyEq(f.facet(@nodoc), null)
    verifyEq(f.facet(@nodoc, "!"), "!")
    verifyErr(ReadonlyErr#) |,| { f.facets.set(@nodoc, "!") }

    verifySlotFacet(f, @boolB, true)
    verifySlotFacet(f, @intB, 4)
    verifySlotFacet(f, @strA, "I")

    // since values are immutable we should reuse
    f.facets.keys.each { verifySame(f.facet(it), f.facet(it)) }
  }

  Void testSlotFacets2()
  {
    m := FacetsA#equals
    verifySlotFacet(m, @boolA, true)
  }

  Void testSlotFacetsEmpty()
  {
    m := FacetsA#hash
    verifyEq(m.facets.size, 0)
    verifyEq(m.facet(@boolB), null)
    verifyEq(m.facet(@boolB, "!"), "!")
    verifyEq(m.facets.isImmutable, true)
    verifySame(m.facets, m.facets)
    verifySame(m.facets, type.slot("testSlotFacetsEmpty").facets)
  }

  Void verifySlotFacet(Slot s, Symbol key, Obj expected)
  {
    verifyEq(s.facet(key), expected)
    verifyEq(s.facet(key, "!@#"), expected)
    verifyEq(s.facets[key], expected)
  }

//////////////////////////////////////////////////////////////////////////
// Inherited Facets
//////////////////////////////////////////////////////////////////////////

  Void testInherited()
  {
    t := FacetsB#
    verifyEq(t.facet(@serialC,   null, false), FacetsA { i=2; f=3f; s="gunslinger" })
    verifyEq(t.facet(@serialC,   null, true),  FacetsA { i=2; f=3f; s="gunslinger" })
    verifyEq(t.facet(@strA, null, false), "foo")
    verifyEq(t.facet(@strA, null, true),  "foo")

    verifyEq(t.facet(@floatB, null, false), null)
    verifyEq(t.facet(@floatB, null, true),  Float.nan)
    verifyEq(t.facet(@serializable, null, false), null)
    verifyEq(t.facet(@serializable, null, true),  true)

    verifyEq(t.facet(@strB, null, false), null)
    verifyEq(t.facet(@strB, null, true),  "ma")
    verifyEq(t.facet(@intB, "x", false),  "x")
    verifyEq(t.facet(@intB, null, true),  'b')

    f := t.facets(true)
    verifyEq(f.size, 20)
    verifyEq(f[@serialC], FacetsA { i=2; it.f=3f; s="gunslinger" })
    verifyEq(f[@listD],   [false, Version("8"), FacetsA { s="tull" }])
    verifyEq(f[@listA],   ["man", "in", "black"])
    verifyEq(f[@strA],    "foo")
    verifyEq(f[@floatA],  2.4f)
    verifyEq(f[@durA],    3min)
    verifyEq(f[@monA],    Month.jun)
    verifyEq(f[@strB],    "ma")
    verifyEq(f[@intB],    'b')

    f = t.facets(false)
    verifyEq(f.size, 4)
  }

}

**************************************************************************
** FacetsA
**************************************************************************

@boolA
@boolB=false
@intA='c'
@strA="a\tb\nc\u0abc!"
@floatA=2.4f
@durA=3min
@uriA=`foo.txt`
@verA=Version("2.3")
@listA=Str[,]
@listB=[1,2,3]
@mapA=[2:"two", 3:"three"]
@floatB=Float.nan
@floatC=Float.posInf
@floatD=Float.negInf
@monA=Month.jun
@serializable
class FacetsA
{
  override Int hash() { return "$i + $f + $s".hash }

  @boolA
  override Bool equals(Obj? obj)
  {
    x := obj as FacetsA
    if (x == null) return false
    return i == x.i &&
           f == x.f &&
           s == x.s
  }

  @boolB @intB=4 @strA="I" Int i
  Float f
  Str? s
}

**************************************************************************
** FacetsB
**************************************************************************

@serialC=FacetsA { i=2; f=3f; s="gunslinger" }
@listD=[false, Version("8"), FacetsA { s="tull" }]
@listA=["man", "in", "black"]
@strA="foo"
class FacetsB : FacetsA, FacetsM
{
}

**************************************************************************
** FacetsM
**************************************************************************

@strB="ma" @intB='b' mixin FacetsM {}