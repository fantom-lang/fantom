//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 06  Brian Frank  Creation
//

**
** EnumTest
**
class EnumTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  Void testType()
  {
    verifyEq(EnumAbc#.signature, "testSys::EnumAbc")
    verifyEq(EnumAbc#.base, Enum#)
    verifyEq(EnumAbc#.isEnum, true)
    verifyEq(EnumAbc#.isClass, false)
    verifyEq(EnumAbc#.isMixin, false)
    verifyEq(Obj#.isEnum, false)
    verifyEq(Str#.isEnum, false)

    verifySame(EnumAbc.A.type, EnumAbc#)

    verify(EnumAbc.A is EnumAbc)
    verify(EnumAbc.A is Enum)
    verify(EnumAbc.A is Obj)
    verifyFalse((Obj)EnumAbc.A is Int)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    verify(EnumAbc.A == EnumAbc.A)
    verify(EnumAbc.A === EnumAbc.A)
    verify(EnumAbc.A != EnumAbc.B)
    verify(EnumAbc.A != EnumAbc.C)
    verify(EnumAbc.B != EnumAbc.C)
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(EnumAbc.A <= EnumAbc.A)
    verify(EnumAbc.A < EnumAbc.B)
    verify(EnumAbc.B < EnumAbc.C)
    verifyFalse(EnumAbc.C < EnumAbc.B)
    verifyFalse(EnumAbc.B < EnumAbc.A)
    verify(EnumAbc.B >= EnumAbc.B)
    verifyFalse(EnumAbc.B > EnumAbc.B)
    verify(EnumAbc.B > EnumAbc.A)

    verifyEq([EnumAbc.B, EnumAbc.C, EnumAbc.A].sort, [EnumAbc.A, EnumAbc.B, EnumAbc.C])
  }

//////////////////////////////////////////////////////////////////////////
// Ordinal
//////////////////////////////////////////////////////////////////////////

  Void testOrdinals()
  {
    verifyEq(EnumAbc.A.ordinal, 0)
    verifyEq(EnumAbc.B.ordinal, 1)
    verifyEq(EnumAbc.C.ordinal, 2)
  }

//////////////////////////////////////////////////////////////////////////
// Names
//////////////////////////////////////////////////////////////////////////

  Void testNames()
  {
    verifyEq(EnumAbc.A.name, "A")
    verifyEq(EnumAbc.B.name, "B")
    verifyEq(EnumAbc.C.name, "C")
  }

//////////////////////////////////////////////////////////////////////////
// To Str
//////////////////////////////////////////////////////////////////////////

  Void testToStr()
  {
    verifyEq(EnumAbc.A.toStr, "A")
    verifyEq(EnumAbc.B.toStr, "B")
    verifyEq(EnumAbc.C.toStr, "C")
  }

//////////////////////////////////////////////////////////////////////////
// Values
//////////////////////////////////////////////////////////////////////////

  Void testValues()
  {
    verifyEq(EnumAbc.values, [EnumAbc.A, EnumAbc.B, EnumAbc.C])
    verifyEq(EnumAbc.values.isRO, true)
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void testParse()
  {
    verifySame(Weekday.fromStr("mon"), Weekday.mon)
    verifySame(Weekday.fromStr("xxx", false), null)
    verifyErr(ParseErr#) |,| { Weekday.fromStr("xxx") }

    verifySame(Month.fromStr("apr"), Month.apr)
    verifySame(Month.fromStr("xxx", false), null)
    verifyErr(ParseErr#) |,| { Month.fromStr("xxx") }

    verifySame(EnumAbc.fromStr("A"), EnumAbc.A)
    verifySame(EnumAbc.fromStr("B"), EnumAbc.B)
    verifySame(EnumAbc.fromStr("C"), EnumAbc.C)
    verifySame(EnumAbc.fromStr("values", false), null)
    verifySame(EnumAbc.fromStr("first", false), null)
    verifySame(EnumAbc.fromStr("foobar", false), null)

    verifySame(Suits.fromStr("clubs"), Suits.clubs)
    verifySame(Suits.fromStr("colors", false), null)

    verifyErr(ParseErr#) |,| { EnumAbc.fromStr("values") }
    verifyErr(ParseErr#) |,| { EnumAbc.fromStr("first", true) }
    verifyErr(ParseErr#) |,| { EnumAbc.fromStr("foo") }
  }

//////////////////////////////////////////////////////////////////////////
// Additional Methods
//////////////////////////////////////////////////////////////////////////

  Void testAdditionalMethods()
  {
    verifyEq(EnumAbc.A.negOrdinal, 0)
    verifyEq(EnumAbc.B.negOrdinal, -1)
    verifyEq(EnumAbc.C.negOrdinal, -2)
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  Void testCtor()
  {
    verifyEq(Suits.values, [Suits.clubs, Suits.diamonds, Suits.hearts, Suits.spades])
    verifyEq(Suits.clubs.ordinal,    0)
    verifyEq(Suits.diamonds.ordinal, 1)
    verifyEq(Suits.hearts.ordinal,   2)
    verifyEq(Suits.spades.ordinal,   3)

    verifyEq(Suits.clubs.color,    "black")
    verifyEq(Suits.diamonds.color, "red")
    verifyEq(Suits.hearts.color,   "red")
    verifyEq(Suits.spades.color,   "black")
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testReflection()
  {
    // enum has fields
    verify(EnumAbc#.slot("A").isField)
    verifyEq(EnumAbc#.field("A").name, "A")
    verifyEq(EnumAbc#.field("A")->getter, null)
    verifyEq(EnumAbc#.field("A")->setter, null)

    // get
    verifyEq(EnumAbc#.field("A").get(null), EnumAbc.A)
    verifyEq(EnumAbc#.field("B")[null], EnumAbc.B)
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  Void testFacets()
  {
    verifyEq(EnumAbc#.facet(@simple), true)
    verifyEq(EnumAbc#.facets, Symbol:Obj?[@simple:true])

    verifyEq(Suits#.facet(@simple), true)
    verifyEq(Suits#.facet(@strA), "y")
    verifyEq(Suits#.facets, Symbol:Obj?[@simple:true, @strA:"y"])
  }

}

internal enum EnumAbc
{
  A, B, C

  Int negOrdinal() { return -ordinal }

  static const EnumAbc first := A
}

@strA="y"
enum Suits
{
  clubs("black"),
  diamonds("red"),
  hearts("red"),
  spades("black")

  private new make(Str color) { this.color = color; }

  const Str color;
}

enum Foo
{
  one,
  two,
  three
}