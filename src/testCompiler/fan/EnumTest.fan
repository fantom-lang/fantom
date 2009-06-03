//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Sep 06  Brian Frank  Creation
//

**
** EnumTest
**
class EnumTest : CompilerTest
{

/////////////////////////////////////////////////////////////////////////
// Simple
//////////////////////////////////////////////////////////////////////////

  Void testSimple()
  {
    compile("enum Foo { a, b, c }")

    t := pod.types.first
    verifyEq(t.isEnum, true)
    verifyEq(t.base, Enum#)

    a := t.field("a")
    verifyEq(a.name, "a")
    verifyEq(a.of, t)
    verifyEq(a.isPublic, true)
    verifyEq(a.isStatic, true)
    verifyEq(a.isConst, true)
    verifyEq(a.get->ordinal, 0)
    verifyEq(a.get->name, "a")

    b := t.field("b")
    verifyEq(b.get->ordinal, 1)
    verifyEq(b.get->name, "b")

    c := t.field("c")
    verifyEq(c.get->ordinal, 2)
    verifyEq(c.get->name, "c")

    v := t.field("values")
    verifyEq(v.of.signature, "$t.qname[]")
    verifyEq(v.isPublic, true)
    verifyEq(v.isStatic, true)
    verifyEq(v.isConst, true)
    verifyEq(v.get->isRO, true)
    verifyEq(v.get->get(0), a.get)
    verifyEq(v.get->get(1), b.get)
    verifyEq(v.get->get(2), c.get)
  }

/////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  Void testConstructor()
  {
    compile(
     "enum Foo
      {
        a(10),
        b(11),
        c(12)

        private new make(Int x) { this.x = x }

        const Int x
      }")

    t := pod.types.first
    verifyEq(t.isEnum, true)
    verifyEq(t.base, Enum#)

    a := t.field("a")
    verifyEq(a.name, "a")
    verifyEq(a.of, t)
    verifyEq(a.isPublic, true)
    verifyEq(a.isStatic, true)
    verifyEq(a.isConst, true)
    verifyEq(a.get->ordinal, 0)
    verifyEq(a.get->name, "a")
    verifyEq(a.get->x, 10)

    b := t.field("b")
    verifyEq(b.get->ordinal, 1)
    verifyEq(b.get->name, "b")
    verifyEq(b.get->x, 11)

    c := t.field("c")
    verifyEq(c.get->ordinal, 2)
    verifyEq(c.get->name, "c")
    verifyEq(c.get->x, 12)

    v := t.field("values")
    verifyEq(v.of.signature, "$t.qname[]")
    verifyEq(v.isPublic, true)
    verifyEq(v.isStatic, true)
    verifyEq(v.isConst, true)
    verifyEq(v.get->isRO, true)
    verifyEq(v.get->get(0), a.get)
    verifyEq(v.get->get(1), b.get)
    verifyEq(v.get->get(2), c.get)
  }

/////////////////////////////////////////////////////////////////////////
// Static Init
//////////////////////////////////////////////////////////////////////////

  Void testStaticInit()
  {
    compile(
     "enum Foo
      {
        a, b, c

        const static Str[] caps
        static
        {
          // verify values are initialized first
          caps = values.map |Foo x->Str| { x.name.upper }
        }
      }")

    t := pod.types.first
    caps := t.field("caps").get
    verifyEq(caps, ["A", "B", "C"])
  }

  Void testStaticInitClosure()
  {
    compile(
     "enum Foo
      {
        a, b, c

        const static Str:Foo map
        static
        {
          m := Str:Foo[:]
          values.each |Foo t| { m[t.name.upper] = t }
          map = m
        }
      }")
    // compiler.fpod.dump
    t := pod.types.first
    map := (Map)t.field("map").get
    verifyEq(map.keys.sort, ["A", "B", "C"])
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrors()
  {
    verifyErrors(
     "mixin X { static Int values() {} abstract Str foo(); }
      enum A { a; Void values() {} }
      enum B : X { a, b }
      enum C { foo;  Str foo() { return null } }
      enum D : X { foo }
      enum E { a, b;  new myMake() {} }
      enum F { a, b;  new make() {}  new make2() {} }
      enum G { a, b;  new make() {} }
      enum H { a, b;  private new make(Int o, Str n) : super(o, n) {} }
      @simple enum I { a, b }
      ",
       [
         2, 13, "Enum 'values' conflicts with slot",
         3, 1,  "Enum 'values' conflicts with inherited slot '$podName::X.values'",
         4, 16, "Enum 'foo' conflicts with slot",
         5, 14, "Enum 'foo' conflicts with inherited slot '$podName::X.foo'",
         6, 17, "Enum constructor must be named 'make'",
         7, 32, "Enum constructor must be named 'make'",
         8, 17, "Enum constructor must be private",
         9, 17, "Enum constructor cannot call super constructor",
        10,  2, "Facet 'simple' conflicts with auto-generated facet",
       ])
  }
}