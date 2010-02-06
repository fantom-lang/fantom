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
    compile("enum class Foo { a, b, c }")

    t := pod.types.first
    verifyEq(t.isEnum, true)
    verifyEq(t.base, Enum#)

    a := t.field("a")
    verifyEq(a.name, "a")
    verifyEq(a.type, t)
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

    v := t.field("vals")
    verifyEq(v.type.signature, "$t.qname[]")
    verifyEq(v.isPublic, true)
    verifyEq(v.isStatic, true)
    verifyEq(v.isConst, true)
    verifyEq(v.get->isRO, true)
    verifyEq(v.get->isImmutable, true)
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
     "enum class Foo
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
    verifyEq(a.type, t)
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

    v := t.field("vals")
    verifyEq(v.type.signature, "$t.qname[]")
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
     "enum class Foo
      {
        a, b, c

        const static Str[] caps
        static
        {
          // verify vals are initialized first
          caps = vals.map |Foo x->Str| { x.name.upper }
        }
      }")

    t := pod.types.first
    caps := t.field("caps").get
    verifyEq(caps, ["A", "B", "C"])
  }

  Void testStaticInitClosure()
  {
    compile(
     "enum class Foo
      {
        a, b, c

        const static Str:Foo map
        static
        {
          m := Str:Foo[:]
          vals.each |Foo t| { m[t.name.upper] = t }
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
     """const class X : Enum {}
        """,
       [
         1, 17, "Cannot inherit 'Enum' explicitly",
       ])


    // InitEnum
    verifyErrors(
     "mixin X { static Int vals() {} abstract Str foo(); }
      enum class A { a; Void vals() {} }
      enum class B : X { a, b }
      enum class C { foo;  Str foo() { return null } }
      enum class D : X { foo }
      enum class E { a, b;  new myMake() {} }
      enum class F { a, b;  new make() {}  new make2() {} }
      enum class G { a, b;  new make() {} }
      enum class H { a, b;  private new make(Int o, Str n) : super(o, n) {} }
      ",
       [
         2, 19, "Enum 'vals' conflicts with slot",
         3, 6,  "Enum 'vals' conflicts with inherited slot '$podName::X.vals'",
         4, 22, "Enum 'foo' conflicts with slot",
         5, 20, "Enum 'foo' conflicts with inherited slot '$podName::X.foo'",
         6, 23, "Enum constructor must be named 'make'",
         7, 38, "Enum constructor must be named 'make'",
         8, 23, "Enum constructor must be private",
         9, 23, "Enum constructor cannot call super constructor",
       ])

    // CheckErrors
    verifyErrors(
     "@Serializable enum class I { a, b }
      ",
       [
        1, 1, "Duplicate facet 'sys::Serializable'",
       ])
  }
}