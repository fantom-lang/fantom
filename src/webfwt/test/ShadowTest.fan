//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jul 2011  Andy Frank  Creation
//

using gfx

internal class ShadowTest : Test
{
  Void testStr()
  {
    verifyShadow(Shadow(""),             Color.black, 0,  0, 0, 0)
    verifyShadow(Shadow("#f00 0 -1"),    Color.red,   0, -1, 0, 0)
    verifyShadow(Shadow("#f00 1 2 3"),   Color.red,   1,  2, 3, 0)
    verifyShadow(Shadow("#0f0 1 2 3 4"), Color.green, 1,  2, 3, 4)

    verifyEq(Shadow("#3c3c3c 1 2").toStr,  "#3c3c3c 1 2")
    verifyEq(Shadow("#fff 0 -1").toStr,    "#ffffff 0 -1")
    verifyEq(Shadow("#fff 1 2 3").toStr,   "#ffffff 1 2 3")
    verifyEq(Shadow("#fff 1 2 0 4").toStr, "#ffffff 1 2 0 4")

    verifyEq(Shadow.fromStr("xyz", false), null)
    verifyEq(Shadow.fromStr("#000 1 b", false), null)

    verifyErr(ParseErr#) |->| { x := Shadow("1") }
    verifyErr(ParseErr#) |->| { x := Shadow("1 b") }
    verifyErr(ParseErr#) |->| { x := Shadow("foo 1 1") }
    verifyErr(ParseErr#) |->| { x := Shadow("#fff 1 1 0.5") }
    verifyErr(ParseErr#) |->| { x := Shadow("#fff 1 2 3 4 5") }
  }

  Void testCss()
  {
    verifyEq(Shadow("").toCss, "0px 0px #000000")
    verifyEq(Shadow("#f00 1 1").toCss, "1px 1px #ff0000")
    verifyEq(Shadow("#f00 -1 -1 2").toCss, "-1px -1px 2px #ff0000")
    verifyEq(Shadow("#f00 -1 -1 2 5").toCss, "-1px -1px 2px 5px #ff0000")
    verifyEq(Shadow("#f00 1 1 0 3").toCss, "1px 1px 0px 3px #ff0000")
  }

  private Void verifyShadow(Shadow sh, Color c, Int x, Int y, Int b, Int s)
  {
    verifyEq(sh.color,    c)
    verifyEq(sh.offset.x, x)
    verifyEq(sh.offset.y, y)
    verifyEq(sh.blur,     b)
    verifyEq(sh.spread,   s)

    test := Shadow { offset=Point(x,y); blur=b; spread=s; color=c }
    verifyEq(sh.toStr, test.toStr)
    verifyEq(Shadow.fromStr(sh.toStr), test)
  }
}