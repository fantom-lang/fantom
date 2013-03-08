//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 08  Brian Frank  Creation
//   08 Feb 13  Ivo Smid     Conversion of Java class to JS
//

**
** UuidTest
**
@Js
class UuidTestJs : Test
{

  Void testIdentity()
  {
    if (Env.cur.runtime != "js") return

    verifyErr(UnsupportedErr#) { x := Uuid() }
    verifyErr(UnsupportedErr#) { x := Uuid.makeBits(0xaabb_ccdd_0022_0345, 0x0123_ff00eecc5577) }

    strUuid := "aabbccdd-0022-0345-0123-ff00eecc5577"
    a := Uuid.fromStr(strUuid)

    // bits
    verifyErr(UnsupportedErr#) { a.bitsHi }
    verifyErr(UnsupportedErr#) { a.bitsLo }

    // equals
    verifyEq(a, Uuid.fromStr(strUuid))
    verifyNotEq(a, Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc5576"))

    // hash
    verifyEq(a.hash, strUuid.hash)

    // compare
    verifyEq(a <=> Uuid.fromStr(strUuid), 0)
    verifyEq(a < Uuid.fromStr("aabbccdd-0022-0346-0123-ff00eecc5577"), true)
    verifyEq(a > Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc5578"), false)

    // str
    verifyEq(a.toStr, strUuid)

    // type
    verifySame(Type.of(a), Uuid#)
  }

  Void testParse()
  {
    if (Env.cur.runtime != "js") return

    strUuid := "aabbccdd-0022-0345-0123-ff00eecc5577"
    x := Uuid(strUuid)
    buf := Buf()
    buf.writeObj(x)
    verifyEq(buf.flip.readObj, x)

    verifyEq(Uuid.fromStr("xxxx", false), null)
    verifyErr(ParseErr#) { z := Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc557x") }
    verifyErr(ParseErr#) { z := Uuid.fromStr("aabbccdd-0022-0345-0123-ff00eecc5577a", true) }
  }

  Void verifyParse(Uuid x)
  {
    verifyEq(x.toStr.size, 36)
    y := Uuid(x.toStr)
    verifyEq(x, y)
  }

}