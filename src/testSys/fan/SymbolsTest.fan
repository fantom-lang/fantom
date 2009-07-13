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
    x := type.pod.symbol("boolT")
    verifyEq(x.name, "boolT")
    verifyEq(x.qname, "testSys::boolT")
    verifySame(x.pod, type.pod)
    verifyEq(x.of, Bool#)
    verifyEq(x.val, true)
    verifyEq(x.defVal, true)
    verifyEq(x, type.pod.symbol("boolT"))
    verifySame(x, type.pod.symbol("boolT"))

    x = type.pod.symbol("boolF")
    verifyEq(x.of, Bool#)
    verifyEq(x.val, false)
    verifyEq(x.defVal, false)

    x = type.pod.symbol("intA")
    verifyEq(x.of, Int#)
    verifyEq(x.val, 0xabcd_0123_eeff_7788)
    verifyEq(x.defVal, 0xabcd_0123_eeff_7788)
    verifySame(x.defVal, x.defVal)
  }
}