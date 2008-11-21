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
// Primitive Params
//////////////////////////////////////////////////////////////////////////

  Void testPrimitives()
  {
    compile(
     "using [java] fanx.test
      class Foo
      {
        Obj init() { return InteropTest() }

        Int setb(Obj o, Int v) { x := (InteropTest)o; x.numb(v); return x.numl }
        Int sets(Obj o, Int v) { x := (InteropTest)o; x.nums(v); return x.numl }
        Int seti(Obj o, Int v) { x := (InteropTest)o; x.numi(v); return x.numl }
        Int setl(Obj o, Int v) { x := (InteropTest)o; x.numl(v); return x.numl }
        Int setf(Obj o, Float v) { x := (InteropTest)o; x.numf(v); return x.numl }

        Int getb(Obj o) { return ((InteropTest)o).numb }
        Int gets(Obj o) { return ((InteropTest)o).nums }
        Int geti(Obj o) { return ((InteropTest)o).numi }
        Float getf(Obj o) { return ((InteropTest)o).numf }

        Int add(Obj o, Int b, Int s, Int i, Float f) { x := (InteropTest)o; x.numadd(b, s, i, f); return x.numl }
      }")

    obj := pod.types.first.make
    x := obj->init

    // long -> byte -> long
    verifyEq(obj->setb(x, 127), 127)
    verifyEq(obj->setb(x, -127), -127)
    verifyEq(obj->setb(x, 0xff7a), 0x7a)
    verifyEq(obj->getb(x), 0x7a)
    verifyEq(obj->setl(x, -1), -1)
    verifyEq(obj->getb(x), -1)

    // long -> short -> long
    verifyEq(obj->sets(x, 32_000), 32_000)
    verifyEq(obj->sets(x, -32_000), -32_000)
    verifyEq(obj->sets(x, 0x1234_7abc), 0x7abc)
    verifyEq(obj->gets(x), 0x7abc)
    verifyEq(obj->setl(x, 0xffff_0123), 0xffff_0123)
    verifyEq(obj->gets(x), 0x123)

    // long -> int -> long
    verifyEq(obj->seti(x, -44), -44)
    verifyEq(obj->geti(x), -44)
    verifyEq(obj->seti(x, 0xff_1234_abcd), 0x1234_abcd)
    verifyEq(obj->geti(x), 0x1234_abcd)
    verifyEq(obj->setl(x, 0xff_1234_abcd), 0xff_1234_abcd)
    verifyEq(obj->geti(x), 0x1234_abcd)

    // double -> float -> long
    verifyEq(obj->setf(x, 88f), 88)
    verifyEq(obj->getf(x), 88f)

    // multiple primitives on stack
    verifyEq(obj->add(x, 3, 550, -50, -50f), 453)
  }

}