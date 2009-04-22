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
}