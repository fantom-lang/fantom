//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Mar 08  Brian Frank  Creation
//

using compiler

**
** ScriptTest
**
class ScriptTest : CompilerTest
{

  Void testCompile()
  {
    f := tempDir + `test.fan`
    f.out.print("class Foo { Int x() { return 2008 } }").close

    t1 := Sys.compile(f)
    verifyEq(t1.make->x, 2008)

    t2 := Sys.compile(f)
    verifySame(t1, t2)
    verifyEq(t2.make->x, 2008)

    f.out.print("class Foo { Str x() { return \"2009\" } }").close
    t3 := Sys.compile(f)
    verifyNotSame(t1, t3)
    verifyEq(t3.make->x, "2009")

    t4 := Sys.compile(f, ["force":false])
    verifySame(t3, t4)
    t5 := Sys.compile(f, ["force":true])
    verifyNotSame(t3, t5)
  }

  Void testCompileType()
  {
    f := tempDir + `test.fan`
    f.out.print(
     "class C { }
      class A { }
      class B { }"
    ).close

    t := Sys.compile(f)
    verifyEq(t.name, "C")

    f.out.print(
     "internal class C { }
      class A { }
      class B { }"
    ).close

    t = Sys.compile(f)
    verifyEq(t.name, "A")
  }

  Void testCompileOptions()
  {
    f := tempDir + `test.fan`
    f.out.print("class Foo {}").close

    log := CompilerLog.make

    Sys.compile(f, ["log":log, "logLevel":LogLevel.silent])
    verifyEq(log.level, LogLevel.silent)

    Sys.compile(f, ["log":log, "logLevel":LogLevel.error, "force":true])
    verifyEq(log.level, LogLevel.error)
  }

  Void testCompileError()
  {
    f := tempDir + `test.fan`
    f.out.print("class Foo { Void x(Intx p) {} }").close

    try
    {
      Sys.compile(f, ["logLevel":LogLevel.silent])
      fail
    }
    catch (CompilerErr e)
    {
      verifyEq(e.message, "Unknown type 'Intx'")
      verifyEq(e.col, 20)
    }
  }
}