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
// #530 Ctor bug with default params
//////////////////////////////////////////////////////////////////////////

  Void test530()
  {
     compile(
       "class Foo
        {
          static Str testAc() { return c(\"1234567890\").z }
          static Str testBc() { return c(\"1234567890\", 255).z }
          static Str testCc() { return c(\"1234567890\", 255, \"foo\").z }

          static Str testAi() { return make.i(\"1234567890\") }
          static Str testBi() { return make.i(\"1234567890\", 255) }
          static Str testCi() { return make.i(\"1234567890\", 255, \"foo\") }

          static Str testAs() { return s(\"1234567890\") }
          static Str testBs() { return s(\"1234567890\", 255) }
          static Str testCs() { return s(\"1234567890\", 255, \"foo\") }

          new c(Str a, Int b := a.size, Str c := b.toHex) { z = [a, b, c].join(\",\") }
          Str i(Str a, Int b := a.size, Str c := b.toHex) { [a, b, c].join(\",\") }
          static Str s(Str a, Int b := a.size, Str c := b.toHex) { [a, b, c].join(\",\") }

          new make() {}
          Str? z
        }
        ")

    obj := pod.types.first.make
    verifyEq(obj->testAc, "1234567890,10,a")
    verifyEq(obj->testBc, "1234567890,255,ff")
    verifyEq(obj->testCc, "1234567890,255,foo")
    verifyEq(obj->testAi, "1234567890,10,a")
    verifyEq(obj->testBi, "1234567890,255,ff")
    verifyEq(obj->testCi, "1234567890,255,foo")
    verifyEq(obj->testAs, "1234567890,10,a")
    verifyEq(obj->testBs, "1234567890,255,ff")
    verifyEq(obj->testCs, "1234567890,255,foo")
  }

//////////////////////////////////////////////////////////////////////////
// #542 Compiler - Internal class cast error
//////////////////////////////////////////////////////////////////////////

  Void test542()
  {
     compile(
     "class Test
      {
        Str:Obj bindings := [
          \"print\": |Obj[] args|
          {
            args.each |arg| { result += arg + \",\" }
          }
        ]
        Str result := \"\"
      }")

    obj := pod.types.first.make
    Func f := obj->bindings->get("print")
    f.call(["a", "b", "c"])
    verifyEq(obj->result, "a,b,c,")
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

          Str a(Func f) { return f.call(36) }
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

//////////////////////////////////////////////////////////////////////////
// #664 Nullable params w/out name in func sig
//////////////////////////////////////////////////////////////////////////

  Void test664()
  {
     compile(
       "class Foo
        {
          Void m00(|Int? x| f) {}
          Void m01(|Int?| f) {}
          Void m02(|Int? x->Void| f) {}
          Void m03(|Int?->Void| f) {}
          Void m04(|Int,Str? x->Pod?| f) {}
          Void m05(|Int,Str?->Pod?| f) {}
        }
        ")

    t := pod.types[0]
    verifyEq(t.method("m00").params[0].of.signature, "|sys::Int?->sys::Void|")
    verifyEq(t.method("m01").params[0].of.signature, "|sys::Int?->sys::Void|")
    verifyEq(t.method("m02").params[0].of.signature, "|sys::Int?->sys::Void|")
    verifyEq(t.method("m03").params[0].of.signature, "|sys::Int?->sys::Void|")
    verifyEq(t.method("m04").params[0].of.signature, "|sys::Int,sys::Str?->sys::Pod?|")
    verifyEq(t.method("m05").params[0].of.signature, "|sys::Int,sys::Str?->sys::Pod?|")
  }

//////////////////////////////////////////////////////////////////////////
// #676 Compiler bug? walkback in closure type inference
//////////////////////////////////////////////////////////////////////////

  Void test676()
  {
     compile(
       "class Foo
        {
          Str test(List list)
          {
            list.join(\",\") |item| { item->toHex }
          }
        }
        ")

    obj := pod.types[0].make
    verifyEq(obj->test([0xa, 0x7, 0xc]), "a,7,c")
  }

//////////////////////////////////////////////////////////////////////////
// #788 Coercion in IndexedAssignExpr
//////////////////////////////////////////////////////////////////////////

  Void test788()
  {
     compile(
       "class Foo
        {
          Int[] list := Int[2, 3, 4]
          Int[] test(Int? i)
          {
            list[i] += 1
            return list
          }
        }
        ")

    obj := pod.types[0].make
    verifyEq(obj->test(0), [3, 3, 4])
    verifyEq(obj->test(2), [3, 3, 5])
  }

//////////////////////////////////////////////////////////////////////////
// #731 Method calls should always require parens
//////////////////////////////////////////////////////////////////////////

  Void test731()
  {
    // parser stage
    verifyErrors(
     "class Foo { Void foo(Int x) { echo \"foo\$x\" } }",
       [
         1, 31, "Expected expression statement",
       ])
  }

}