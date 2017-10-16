//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Sep 2015  Andy Frank  Creation
//

**
** GeomTest
**
@Js
class GeomTest : Test
{
  Void testCssDim()
  {
    verifyEq(CssDim#.make,  CssDim(0, "px"))
    verifyEq(CssDim.defVal, CssDim(0, "px"))
    verifyEq(CssDim.defVal, CssDim("0px"))
    verifyEq(CssDim.defVal.toStr, "0px")

    verifyCssDim(CssDim("-1em"),         -1, "em")
    verifyCssDim(CssDim(100, "px"),     100, "px")
    verifyCssDim(CssDim(1.25f, "%"),  1.25f, "%")
    verifyCssDim(CssDim("-10.1vw"),  -10.1f, "vw")

    verifyCssDim(CssDim("auto"), 0, "auto")
    verifyEq(CssDim("auto").toStr, "auto")

    verifyErr(ParseErr#) { d := CssDim.fromStr("100") }
    verifyErr(ParseErr#) { d := CssDim.fromStr("abc") }
    verifyErr(ParseErr#) { d := CssDim.fromStr("100 %") }
    verifyErr(ParseErr#) { d := CssDim.fromStr("-100 px") }

    verifySer(CssDim(5, "px"))
    verifySer(CssDim(-5, "px"))
    verifySer(CssDim(1.25f, "%"))
    verifySer(CssDim(-5.001f, "em"))
  }

  Void verifyCssDim(CssDim d, Num v, Str u)
  {
    verifyEq(d.val, v)
    verifyEq(d.unit, u)
  }

  Void verifySer(Obj obj)
  {
    //echo("-- " + Buf.make.writeObj(obj).flip.readAllStr)
    x := Buf.make.writeObj(obj).flip.readObj
    verifyEq(obj, x)
  }
}