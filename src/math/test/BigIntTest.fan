//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jun 25  Brian Frank  Creation
//

class BigIntTest : Test
{
  Void testGetSet()
  {
    i := BigInt("123")
    verifyEq(i.typeof, BigInt#)

    verifyEq(BigInt.defVal, BigInt(0))
    verifyEq(BigInt.zero,   BigInt(0))
    verifyEq(BigInt.one,    BigInt(1))

    verifyEq(i + 3, BigInt("126"))
    verifyEq(i - 3, BigInt("120"))
  }
}

