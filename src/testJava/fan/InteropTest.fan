//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Nov 08  Brian Frank  Creation
//

using testCompiler

**
** InteropTest
**
class InteropTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    compile(
     "using [java] java.lang
      class Foo
      {
        Str? a(Str key) { return System.getProperty(key) }
        Str? b(Str key, Str def) { return System.getProperty(key, def) }
      }")

    obj := pod.types.first.make
    verifyEq(obj->a("java.home"), Sys.env["java.home"])
    verifyEq(obj->a("bad one"), null)
    verifyEq(obj->b("bad one", "default"), "default")
  }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  Void testCtors()
  {
    compile(
     "using [java] java.util
      class Foo
      {
        Int a() { return Date().getTime }
        Int b() { return Date(1_000_000).getTime }
      }")

    obj := pod.types.first.make
    verify(DateTime.fromJava(obj->a) - DateTime.now < 50ms)
    verifyEq(obj->b, 1_000_000)
  }

//////////////////////////////////////////////////////////////////////////
// Primitives
//////////////////////////////////////////////////////////////////////////

  Void testPrimitives()
  {
    compile(
     "using [java] fanx.test
      class Foo
      {
        Obj init() { return InteropTest() }

        Int b(Obj o, Int v) { x := (InteropTest)o; x.numb(v); return x.numl }
        Int s(Obj o, Int v) { x := (InteropTest)o; x.nums(v); return x.numl }
        Int i(Obj o, Int v) { x := (InteropTest)o; x.numi(v); return x.numl }

        Int f(Obj o, Float v) { x := (InteropTest)o; x.numf(v); return x.numl }

        Int add(Obj o, Int b, Int s, Int i, Float f) { x := (InteropTest)o; x.numadd(b, s, i, f); return x.numl }
      }")

    obj := pod.types.first.make
    x := obj->init

    // long -> byte -> long
    verifyEq(obj->b(x, 127), 127)
    verifyEq(obj->b(x, -127), -127)
    verifyEq(obj->b(x, 0xff7a), 0x7a)

    // long -> short -> long
    verifyEq(obj->s(x, 32_000), 32_000)
    verifyEq(obj->s(x, -32_000), -32_000)
    verifyEq(obj->s(x, 0x1234_7abc), 0x7abc)

    // long -> int -> long
    verifyEq(obj->i(x, -44), -44)
    verifyEq(obj->i(x, 0xff_1234_abcd), 0x1234_abcd)

    // double -> float -> long
    verifyEq(obj->f(x, 88f), 88)

    // multiple primitives on stack
    verifyEq(obj->add(x, 3, 550, -50, -50f), 453)
  }

}