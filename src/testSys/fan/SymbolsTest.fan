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
  Void testImmutable()
  {
    verifyImmutable("boolT",    true)
    verifyImmutable("boolF",    false)
    verifyImmutable("intA",     0xabcd_0123_eeff_7788)
    verifyImmutable("intB",     -4)
    verifyImmutable("floatA",   -5f)
    verifyImmutable("decimalA", 6.7d)
    verifyImmutable("durA",     30ms)
    verifyImmutable("strA",     "alpha")
    verifyImmutable("strB",     "line1\nline2\nline3_\u02c3_")
    verifyImmutable("uriA",     `http://fandev.org/`)
    verifyImmutable("numA",     45,   Num#)
    verifyImmutable("numB",     null, Num?#)
    verifyImmutable("listA",    ["a", "b", "c"])
    verifyImmutable("listB",    [2, 3f, 4d], Num[]#)
    verifyImmutable("listC",    [["a"], ["b"], ["c"]])
  }

  Void verifyImmutable(Str name, Obj? val, Type of := val.type)
  {
    x := type.pod.symbol(name)
    verifyEq(x, type.pod.symbol(name))
    verifySame(x, type.pod.symbol(name))
    verifyEq(x.name, name)
    verifyEq(x.qname, "testSys::$name")
    verifySame(x.pod, type.pod)
    verifyEq(x.of, of)
    verifyEq(x.val, val)
    verifyEq(x.defVal, val)
    verifySame(x.defVal, x.defVal)
  }
}