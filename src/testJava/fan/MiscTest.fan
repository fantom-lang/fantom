//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Brian Frank  Creation
//

**
** MiscTest
**
class MiscTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Ctor Wrapper
//////////////////////////////////////////////////////////////////////////

  Void testCtorWrapper()
  {
    // test for bug report 423 31-Dec-08
    compile(
     "using [java] fanx.interop::DoubleArray as FloatArray
      class Matrix
      {
        new make(Num[][] rows := Float[][,]) { this.size = rows.size }
        Int size
      }")

    obj := pod.types.first.make
    verifyEq(obj->size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Ctor With Java Arg
//////////////////////////////////////////////////////////////////////////

  Void testCtorWithJavaArg()
  {
    // test for bug report on IRC 13-May-09
    compile(
     "using [java] java.util
      class Foo
      {
        new make(ArrayList? x) { }
        static Foo foo() { make(null) }
        static Foo bar() { Foo(null) }
      }")

    obj := pod.types.first.make([null])
    verifyEq(Type.of(obj->foo).name, "Foo")
    verifyEq(Type.of(obj->bar).name, "Foo")
  }

//////////////////////////////////////////////////////////////////////////
// #629 NoClassDefFoundError when accessing public static final field with JavaFFI
//////////////////////////////////////////////////////////////////////////

  Void test629()
  {
    // test for bug report 423 31-Dec-08
    compile(
     "using [java] java.io
      class Foo
      {
        static Int foo() { ObjectStreamConstants.PROTOCOL_VERSION_1 }
      }")

    obj := pod.types.first.make
    verifyEq(obj->foo, 1)
  }

//////////////////////////////////////////////////////////////////////////
// #965 Compiler TypeParser doesn't handle Java FFI
//////////////////////////////////////////////////////////////////////////

  Void test965()
  {
    aPod := podName
    compile(
     "using [java] java.util::Date as JDate
      class Foo
      {
        static JDate[] a() { [JDate(123456789)] }
        static Void b(|JDate?|? f) { f(JDate(987654321)) }
      }")

    depends = [Depend("sys 1.0"), Depend("$aPod 0+")]
    compile(
     "using $aPod
      using [java] java.util::Date as JavaDate
      class Bar
      {
        JavaDate a() { Foo.a.first }
        JavaDate b() { x := null; Foo.b |y| { x = y }; return x }
      }")

    obj := pod.types.first.make
    verifyEq(obj->a->getTime, 123456789)
    verifyEq(obj->b->getTime, 987654321)
  }

//////////////////////////////////////////////////////////////////////////
// #1067 compilerJava - findMethods() patch
//////////////////////////////////////////////////////////////////////////

  Void test1067()
  {
    compile(
     """using [java] fanx.test::InteropTest\$ComboA as ComboA
        using [java] fanx.test::InteropTest\$ComboB as ComboB
        using [java] fanx.test::InteropTest\$ComboC as ComboC
        using [java] fanx.test::InteropTest\$ComboD as ComboD
        class Foo : ComboD
        {
          override Str? foo(Str? x) { x }
          Str? test1(ComboA a) { a.foo("1") }
          Str? test2(ComboB b) { b.foo("2") }
          Str? test3(ComboC c) { c.foo("3") }
          Str? test4(ComboD d) { d.foo("4") }
        }""")

    obj := pod.types.first.make
    verifyEq(obj->foo("0"), "0")
    verifyEq(obj->test1(obj), "1")
    verifyEq(obj->test2(obj), "2")
    verifyEq(obj->test3(obj), "3")
    verifyEq(obj->test4(obj), "4")
  }

}