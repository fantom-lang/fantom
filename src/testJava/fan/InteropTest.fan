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

}