//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Mar 08  Brian Frank  Creation
//

using compiler

**
** RegressionTest
**
class RegressionTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// #528 Compiler bug - duplicate slot x$num
//////////////////////////////////////////////////////////////////////////

  Void test528()
  {
     compile(
       "class Foo
        {
          Str test()
          {
            key := \"testCompiler.528\"
            Actor.locals[key] = \"\"
            2.times |Int i| { 1.times |Int j| { Actor.locals[key] = Actor.locals[key] + i.toStr + \",\" } }
            3.times |Int i| { 2.times |Int j| { Actor.locals[key] = Actor.locals[key] + i.toStr + \",\"} }
            return Actor.locals[key]
          }
        }
        ")

    obj := pod.types.first.make
    verifyEq(obj->test, "0,1,0,0,1,1,2,2,")
  }

//////////////////////////////////////////////////////////////////////////
// #529 Private method in mixin bad classfile
//////////////////////////////////////////////////////////////////////////

  Void test529()
  {
     compile(
       "mixin M
        {
          Str i() { return priI + \" \" + intI  }
          static Str s() { return priS + \" \" + intS }
          private Str priI() { return \"private instance\" }
          private Str intI() { return \"internal instance\" }
          private static Str priS() { return \"private static\" }
          private static Str intS() { return \"internal static\" }
        }

        class Foo : M {}
        ")

    obj := pod.types[1].make
    verifyEq(obj->i, "private instance internal instance")
    verifyEq(obj->s, "private static internal static")
  }

//////////////////////////////////////////////////////////////////////////
// #542 Compiler - Internal class cast error
//////////////////////////////////////////////////////////////////////////

  Void test542()
  {
    verifyErrors(
     "class Test
      {
        Str:Obj bindings := [
          \"printLine\": |Obj[] args|
          {
            str := \"\"
            args.each |arg| { str += arg }
          }
        ]
      }",
      [
        7, 25, "Nested closures not supported in field initializer",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// #542 Compiler - Chaining dynamic calls
//////////////////////////////////////////////////////////////////////////

  Void test543()
  {
     compile(
       "class Foo
        {
          Int[] foo()
          {
            Obj x := Foo()
            acc := Int[,]
            x->things->each |t| { acc.add(t) }
            return acc
          }

          Int[] things := [1, 2, 3]
        }")

    obj := pod.types.first.make
    verifyEq(obj->foo, [1, 2, 3])
  }

//////////////////////////////////////////////////////////////////////////
// #561 Compiler: Internal error
//////////////////////////////////////////////////////////////////////////

  Void test561()
  {
     compile(
       "class Foo
        {
          Func f() { return |Int i->Str| { i.toStr } }
          Func g() { return |Int i->Str| { i.toStr } }

          Str a(Func f) { return f.call1(36) }
          Str b(|Int i->Str| f) { return f(36) }

          Obj test0() { a(f) }
          Obj test1() { a(g) }
          Obj test2() { b(f) }
          Obj test3() { b(g) }
        }")

    obj := pod.types.first.make
    verifyEq(obj->test0, "36")
    verifyEq(obj->test1, "36")
    verifyEq(obj->test2, "36")
    verifyEq(obj->test3, "36")
  }

}