//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

**
** SymbolsTest
**
class SymbolsTest : Test
{
  Void testBasics()
  {
    verifyImmutable(@testSys::boolA, "boolA",  true)
    verifyImmutable(@boolB, "boolB",    false)
    verifyImmutable(@intA, "intA",     0xabcd_0123_eeff_7788)
    verifyImmutable(@intB, "intB",     -4)
    verifyImmutable(@floatA, "floatA",   -5f)
    verifyImmutable(@decimalA, "decimalA", 6.7d)
    verifyImmutable(@durA, "durA",     30ms)
    verifyImmutable(@strA, "strA",     "alpha")
    verifyImmutable(@strB, "strB",     "line1\nline2\nline3_\u02c3_")
    verifyImmutable(@uriA, "uriA",     `http://fandev.org/`)
    verifyImmutable(@numA, "numA",     45,   Num#)
    verifyImmutable(@numB, "numB",     null, Num?#)

    verifyImmutable(@listA, "listA",  ["a", "b", "c"])
    verifyImmutable(@listB, "listB",  [2, 3f, 4d], Num[]#)
    verifyImmutable(@listC, "listC",  [["a"], ["b"], ["c"]])
    verifyMutable(@listD, "listD",    [SerA { i = 0 }, SerA { i = 1 }, SerA { i = 2 }], Obj[]#)

    verifyImmutable(@mapA, "mapA", [0:"zero", 1:"one"])
    verifyMutable(@mapB, "mapB",   [2: SerA { i = 2 }, 3: SerA { i = 3 }])

    verifyImmutable(@serialA, "serialA", Version("2.3"))
    verifyImmutable(@serialB, "serialB", [Version("1"), Version("2")])
    verifyMutable(@serialC, "serialC", SerA { i = 12345; s = "symbols!"}, Obj#)
  }

  Void verifyImmutable(Symbol x, Str name, Obj? val, Type of := val.type)
  {
    verifySymbol(x, name, val, of)
    verifySame(x.defVal, x.defVal)
  }

  Void verifyMutable(Symbol x, Str name, Obj? val, Type of := val.type)
  {
    verifySymbol(x, name, val, of)
    verifyNotSame(x.defVal, x.defVal)
  }

  Void verifySymbol(Symbol x, Str name, Obj? val, Type of := val.type)
  {
    verifyEq(x, type.pod.symbol(name))
    verifySame(x, type.pod.symbol(name))
    verifyEq(x.name, name)
    verifyEq(x.qname, "testSys::$name")
    verifyEq(x.toStr, "@testSys::$name")
    verifySame(x.pod, type.pod)
    verifyEq(x.of, of)
    verifyEq(x.val, val)
    verifyEq(x.defVal, val)
  }


}