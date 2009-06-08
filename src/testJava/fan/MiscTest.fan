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
    verifyEq(obj->foo.type.name, "Foo")
    verifyEq(obj->bar.type.name, "Foo")
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

}