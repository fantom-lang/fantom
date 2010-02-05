//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 09  Brian Frank  Creation
//

**
** BorderTest
**
@Js
class BorderTest : Test
{
  const Int solid   := Border.styleSolid
  const Int inset   := Border.styleInset
  const Int outset  := Border.styleOutset
  const Color black := Color.black
  const Color red   := Color.red
  const Color green := Color.green
  const Color blue  := Color.blue

  Void test()
  {
    // width
    verifyBorder("2",       [2],       [solid], [black], [0], "2 solid #000000 0")
    verifyBorder("2,3",     [2,3,2,3], [solid], [black], [0], "2,3 solid #000000 0")
    verifyBorder("2,3,4",   [2,3,4,3], [solid], [black], [0], "2,3,4 solid #000000 0")
    verifyBorder("2,3,4,5", [2,3,4,5], [solid], [black], [0], "2,3,4,5 solid #000000 0")
    verifyBorder("2, 3",    [2,3,2,3], [solid], [black], [0], "2,3 solid #000000 0")
    verifyBorder("2, 3 ,4  ,  5", [2,3,4,5], [solid], [black], [0], "2,3,4,5 solid #000000 0")

    // style
    verifyBorder("solid",       [1],  [solid], [black], [0], "1 solid #000000 0")
    verifyBorder("inset",       [1],  [inset], [black], [0], "1 inset #000000 0")
    verifyBorder("inset,solid", [1],  [inset,solid,inset,solid], [black], [0], "1 inset,solid #000000 0")
    verifyBorder("inset,solid,outset", [1],  [inset,solid,outset,solid], [black], [0], "1 inset,solid,outset #000000 0")
    verifyBorder("inset,solid,outset,inset", [1],  [inset,solid,outset,inset], [black], [0], "1 inset,solid,outset,inset #000000 0")

    // color
    verifyBorder("#000", [1],  [solid], [black], [0], "1 solid #000000 0")
    verifyBorder("#ff0000", [1],  [solid], [red], [0], "1 solid #ff0000 0")
    verifyBorder("#f00, #0f0", [1], [solid], [red, green, red, green], [0], "1 solid #ff0000,#00ff00 0")
    verifyBorder("#f00,#0f0,#00f", [1], [solid], [red, green, blue, green], [0], "1 solid #ff0000,#00ff00,#0000ff 0")
    verifyBorder("#f00, #0f0 ,#00f,#000", [1], [solid], [red, green, blue, black], [0], "1 solid #ff0000,#00ff00,#0000ff,#000000 0")

    // radius
    verifyBorder("1 3", [1],  [solid], [black], [3], "1 solid #000000 3")
    verifyBorder("1 3, 4", [1],  [solid], [black], [3,4,3,4], "1 solid #000000 3,4")
    verifyBorder("solid 3, 4 ,5", [1],  [solid], [black], [3,4,5,4], "1 solid #000000 3,4,5")
    verifyBorder("1 3,4,5,6", [1],  [solid], [black], [3,4,5,6], "1 solid #000000 3,4,5,6")

    // combos
    verifyBorder("2 inset #00ff00 3", [2], [inset], [green], [3], "2 inset #00ff00 3")
    verifyBorder("1,2 inset #00ff00 3,0,0,2", [1,2,1,2], [inset], [green], [3,0,0,2], "1,2 inset #00ff00 3,0,0,2")
    verifyBorder("0,1,1,1 solid #00f 0,0,2,2", [0,1,1,1], [solid], [blue], [0,0,2,2], "0,1,1 solid #0000ff 0,0,2,2")

    // errors
    verifyEq(Border.fromStr("%", false), null)
    verifyEq(Border.fromStr("% 3", false), null)
    verifyEq(Border.fromStr("1,2,3,4,", false), null)
    verifyEq(Border.fromStr("1,2,3,", false), null)
    verifyEq(Border.fromStr("2 bad", false), null)
    verifyEq(Border.fromStr("2 solid bad", false), null)
    verifyErr(ParseErr#) { Border.fromStr("x", true) }
    verifyErr(ParseErr#) { Border.fromStr("2x") }
    verifyErr(ParseErr#) { Border.fromStr("2 x") }
  }

  Void verifyBorder(Str str, Int[] w, Int[] s, Color[] c, Int[] r, Str normStr)
  {
    expand(w); expand(s); expand(c); expand(r)

    b := Border(str)
    verifyEq(b.toStr, normStr)
    verifyEq(b, Border(normStr))

    verifyEq(b.widthTop,    w[0])
    verifyEq(b.widthRight,  w[1])
    verifyEq(b.widthBottom, w[2])
    verifyEq(b.widthLeft,   w[3])

    verifyEq(b.styleTop,    s[0])
    verifyEq(b.styleRight,  s[1])
    verifyEq(b.styleBottom, s[2])
    verifyEq(b.styleLeft,   s[3])

    verifyEq(b.colorTop,    c[0])
    verifyEq(b.colorRight,  c[1])
    verifyEq(b.colorBottom, c[2])
    verifyEq(b.colorLeft,   c[3])

    verifyEq(b.radiusTopLeft,     r[0])
    verifyEq(b.radiusTopRight,    r[1])
    verifyEq(b.radiusBottomRight, r[2])
    verifyEq(b.radiusBottomLeft,  r[3])
  }

  Void expand(Obj[] list)
  {
    if (list.size == 4) return
    if (list.size != 1) throw Err()
    v := list.first
    list.add(v).add(v).add(v)
  }


}