//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 08  Brian Frank  Creation
//

**
** UuidTest
**
class UuidTest : Test
{

  Void testIdentity()
  {
    a := Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5577)

    // bits
    verifyEq(a.bitsHi, 0xaabb_ccdd_0022_0345)
    verifyEq(a.bitsLo, 0x0123_ff00eecc5577)

    // equals
    verifyEq(a, Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5577))
    verifyNotEq(a, Uuid.makeBits(0xaabb_ccdd_0022_0340, 0x0123_ff00eecc5577))
    verifyNotEq(a, Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5576))

    // hash
    verifyEq(a.hash, 0xaabb_ccdd_0022_0345 ^ 0x0123_ff00eecc5577)

    // compare
    verifyEq(a <=> Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5577), 0)
    verifyEq(a < Uuid.makeBits(0xaabb_ccdd_0022_0346, 0x0123_ff00eecc5577), true)
    verifyEq(a > Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5578), false)

    // str
    verifyEq(a.toStr, "aabbccdd-0022-0345-0123-ff00eecc5577")

    // type
    verifySame(a.type, Uuid#)
  }

  Void testCreated()
  {
    verify((Uuid().createdTicks - DateTime.now.ticks).abs < 10ms.ticks)

    t := Uuid().created
    now := DateTime.now
    verifyEq(t.year, now.year)
    verifyEq(t.month, now.month)
    verifyEq(t.day, now.day)

    t = Uuid("03f0e406-71b5-8740-b9e1-00323f788344").created(TimeZone("New_York"))
    verifyEq(t.year, 2008)
    verifyEq(t.month, Month.dec)
    verifyEq(t.day, 30)
    verifyEq(t.hour, 13)
    verifyEq(t.min, 38)
    verifyEq(t.sec, 12)
  }

  Void testParse()
  {
    verifyParse(Uuid())
    verifyParse(Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5577))

    x := Uuid()
    buf := Buf()
    buf.writeObj(x)
    verifyEq(buf.flip.readObj, x)

    verifyEq(Uuid.fromStr("xxxx", false), null)
    verifyErr(ParseErr#) |,| { Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc557x") }
    verifyErr(ParseErr#) |,| { Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc5577a", true) }
  }

  Void verifyParse(Uuid x)
  {
    verifyEq(x.toStr.size, 36)
    y := Uuid(x.toStr)
    verifyEq(x, y)
  }

}