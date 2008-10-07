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
@testSysByStr="alpha"
@testSysByType=SerA#
class FacetsTest : Test
{
  Str aField;
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
    verifyEq(t.facets.size, 17)
    verifyEq(t.facet("foobarxyz"), null)
    verifyEq(t.facet("foobarxyz", "!"), "!")
    verifyErr(ReadonlyErr#) |,| { t.facets.set("c", "!") }

    verifyTypeFacet(t, "a", true)
    verifyTypeFacet(t, "b", false)
    verifyTypeFacet(t, "c", 'c')
    verifyTypeFacet(t, "d", "a\tb\nc\u0abc!")
    verifyTypeFacet(t, "e", 2.4f)
    verifyTypeFacet(t, "f", 3min)
    verifyTypeFacet(t, "g", `foo.txt`)
    verifyTypeFacet(t, "h", Version.fromStr("2.3"))
    verifyTypeFacet(t, "i", Str[,])
    verifyTypeFacet(t, "j", [1, 2, 3])
    verifyTypeFacet(t, "k", Int:Str[:])
    verifyTypeFacet(t, "l", [2:"two", 3:"three"])
    verifyTypeFacet(t, "m", Float.nan)
    verifyTypeFacet(t, "n", Float.posInf)
    verifyTypeFacet(t, "o", Float.negInf)
    verifyTypeFacet(t, "p", Month.jun)

    // since values are immutable we should reuse
    for (x := 'a'; x <= 'o'; ++x)
      verifySame(t.facet(x.toChar), t.facet(x.toChar))

    // since whole map is immutable we should reuse
    verifySame(t.facets, t.facets)
  }

  Void testTypeFacetsB()
  {
    t := FacetsB#

    verifyTypeFacet(t, "a", FacetsA {i=2; f=3f; s="gunslinger"})
    verifyTypeFacet(t, "b", [false, Version("8"), FacetsA {s="tull"}])
    verifyTypeFacet(t, "c", ["man", "in", "black"])

    verifyNotSame(t.facet("a"), t.facet("a"))
    verifyNotSame(t.facet("b"), t.facet("b"))
    verifySame(t.facet("c"), t.facet("c"))
    verifyNotSame(t.facets, t.facets)
  }

  Void verifyTypeFacet(Type t, Str name, Obj expected)
  {
    verifyEq(t.facet(name), expected)
    verifyEq(t.facet(name, "!@#"), expected)
    verifyEq(t.facets[name], expected)
  }

//////////////////////////////////////////////////////////////////////////
// Slot Facets
//////////////////////////////////////////////////////////////////////////

  Void testSlotFacets1()
  {
    f := FacetsA#.field("i")
    verifyEq(f.facets.isRO, true)
    verifyEq(f.facets.size, 3)
    verifyEq(f.facet("foobarxyz"), null)
    verifyEq(f.facet("foobarxyz", "!"), "!")
    verifyErr(ReadonlyErr#) |,| { f.facets.set("c", "!") }

    verifySlotFacet(f, "x", true)
    verifySlotFacet(f, "y", 4)
    verifySlotFacet(f, "z", "I")

    // since values are immutable we should reuse
    for (x := 'x'; x <= 'z'; ++x)
      verifySame(f.facet(x.toChar), f.facet(x.toChar))

    // since whole map is immutable we should reuse
    verifySame(f.facets, f.facets)
  }

  Void testSlotFacets2()
  {
    m := FacetsA#equals
    verifySlotFacet(m, "wow", true)
    verifySame(m.facets, m.facets)
  }

  Void testSlotFacetsEmpty()
  {
    m := FacetsA#hash
    verifyEq(m.facets.size, 0)
    verifyEq(m.facet("x"), null)
    verifyEq(m.facet("x", "!"), "!")
    verifySame(m.facets, m.facets)
    verifySame(m.facets, type.slot("testSlotFacetsEmpty").facets)
  }

  Void verifySlotFacet(Slot s, Str name, Obj expected)
  {
    verifyEq(s.facet(name), expected)
    verifyEq(s.facet(name, "!@#"), expected)
    verifyEq(s.facets[name], expected)
  }

//////////////////////////////////////////////////////////////////////////
// Inherited Facets
//////////////////////////////////////////////////////////////////////////

  Void testInherited()
  {
    t := FacetsB#
    verifyEq(t.facet("a",   null, false), FacetsA { i=2; f=3f; s="gunslinger" })
    verifyEq(t.facet("a",   null, true),  FacetsA { i=2; f=3f; s="gunslinger" })
    verifyEq(t.facet("foo", null, false), "foo")
    verifyEq(t.facet("foo", null, true),  "foo")

    verifyEq(t.facet("m", null, false), null)
    verifyEq(t.facet("m", null, true),  Float.nan)
    verifyEq(t.facet("serializable", null, false), null)
    verifyEq(t.facet("serializable", null, true),  true)

    verifyEq(t.facet("ma", null, false), null)
    verifyEq(t.facet("ma", null, true),  "ma")
    verifyEq(t.facet("mb", "x", false),  "x")
    verifyEq(t.facet("mb", null, true),  'b')

    f := t.facets(true)
    verifyEq(f.size, 20)
    verifyEq(f["a"],   FacetsA { i=2; f=3f; s="gunslinger" })
    verifyEq(f["b"],   [false, Version("8"), FacetsA { s="tull" }])
    verifyEq(f["c"],   ["man", "in", "black"])
    verifyEq(f["d"],   "a\tb\nc\u0abc!")
    verifyEq(f["e"],   2.4f)
    verifyEq(f["f"],   3min)
    verifyEq(f["p"],   Month.jun)
    verifyEq(f["foo"], "foo")
    verifyEq(f["ma"],  "ma")
    verifyEq(f["mb"],  'b')

    f = t.facets(false)
    verifyEq(f.size, 4)
  }

}

**************************************************************************
** FacetsA
**************************************************************************

@a
@b=false
@c='c'
@d="a\tb\nc\u0abc!"
@e=2.4f
@f=3min
@g=`foo.txt`
@h=Version("2.3")
@i=Str[,]
@j=[1,2,3]
@k=Int:Str[:]
@l=[2:"two", 3:"three"]
@m=Float.nan
@n=Float.posInf
@o=Float.negInf
@p=Month.jun
@serializable
class FacetsA
{
  override Int hash() { return "$i + $f + $s".hash }

  @wow
  override Bool equals(Obj obj)
  {
    x := obj as FacetsA
    if (x == null) return false
    return i == x.i &&
           f == x.f &&
           s == x.s
  }

  @x @y=4 @z="I" Int i
  Float f
  Str s
}

**************************************************************************
** FacetsB
**************************************************************************

@a=FacetsA { i=2; f=3f; s="gunslinger" }
@b=[false, Version("8"), FacetsA { s="tull" }]
@c=["man", "in", "black"]
@foo="foo"
class FacetsB : FacetsA, FacetsM
{
}

**************************************************************************
** FacetsM
**************************************************************************

@ma="ma" @mb='b' mixin FacetsM {}
