//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

using compiler

**
** SymbolsTest
**
class SymbolsTest : CompilerTest
{

  Void testBasics()
  {
    symbolsStr =
    "Int foo := 3
     bar := 10sec"
    compile("class Foo {}")

    x := pod.symbol("foo")
    verifyEq(x.name, "foo")
    verifyEq(x.qname, "${pod.name}::foo")
    verifyEq(x.pod, pod)
    verifyEq(x.of, Int#)
    verifyEq(x.val, 3)

    x = pod.symbol("bar")
    verifyEq(x.name, "bar")
    verifyEq(x.qname, "${pod.name}::bar")
    verifyEq(x.pod, pod)
    verifyEq(x.of, Duration#)
    verifyEq(x.val, 10sec)
  }

  Void testConstFolding()
  {
    symbolsStr =
    """a := -3
       b := 30 * -7
       c := "foo" + "bar"
       """
    compile("class Foo {}")

    x := pod.symbol("a"); verifyEq(x.of, Int#); verifyEq(x.val, -3)
    x = pod.symbol("b");  verifyEq(x.of, Int#); verifyEq(x.val, -210)
    x = pod.symbol("c");  verifyEq(x.of, Str#); verifyEq(x.val, "foobar")
  }

}