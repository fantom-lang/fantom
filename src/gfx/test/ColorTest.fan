//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** ColorTest
**
@Js
class ColorTest : Test
{

  Void testMake()
  {
    c := Color(0xaabbcc)
    verifyEq(c.argb,  0xffaabbcc)
    verifyEq(c.rgb,   0xaabbcc)
    verifyColor(c, 0xff, 0xaa, 0xbb, 0xcc, "#aabbcc")

    c = Color(0xaabbccdd, true)
    verifyEq(c.argb,  0xaabbccdd)
    verifyEq(c.rgb,   0xbbccdd)
    verifyColor(c, 0xaa, 0xbb, 0xcc, 0xdd, "#aabbccdd")

    c = Color.makeArgb(1, 2, 3, 4)
    verifyEq(c.argb,  0x01020304)
    verifyEq(c.rgb,   0x020304)
    verifyColor(c, 1, 2, 3, 4, "#01020304")

    c = Color.makeRgb(0x33, 0x22, 0x11)
    verifyEq(c.argb,  0xff332211)
    verifyEq(c.rgb,   0x332211)
    verifyColor(c, 0xff, 0x33, 0x22, 0x11, "#332211")
  }

  Void verifyColor(Color c, Int a, Int r, Int g, Int b, Str s)
  {
    verifyEq(c.a,     a)
    verifyEq(c.r,     r)
    verifyEq(c.g,     g)
    verifyEq(c.b,     b)
    verifyEq(c.toStr, s)
    verifyEq(c, Color.fromStr(c.toStr))
    verifyEq(c, Buf().writeObj(c).flip.readObj)
    verifyEq(c, Color.makeArgb(a, r, g, b))
  }

  Void testFromStr()
  {
    verifyEq(Color.fromStr("#abc"), Color(0xaabbcc))
    verifyEq(Color.fromStr("#345"), Color(0x334455))
    verifyEq(Color.fromStr("#a4b5c6"), Color(0xa4b5c6))
    verifyEq(Color.fromStr("#dea4b5c6"), Color(0xdea4b5c6, true))

    verifyEq(Color.fromStr("#abdc", false), null)
    verifyErr(ParseErr#) { Color.fromStr("abc") }
    verifyErr(ParseErr#) { Color.fromStr("#xyz", true) }
  }

  Void testEquals()
  {
    verifyEq(Color(0xaabbcc), Color(0xaabbcc))
    verifyEq(Color(0xaabbccdd, true), Color(0xaabbccdd, true))
    verifyNotEq(Color(0xaa0bcc), Color(0xaabbcc))
    verifyNotEq(Color(0xaabbcc), Color(0xaabbcc, true))
    verifyNotEq(Color(0x40aabbcc, true), Color(0x30aabbcc, true))
  }

  Void testToStr()
  {
    verifyEq(Color.black.toStr,  "#000000")
    verifyEq(Color.red.toStr,    "#ff0000")
    verifyEq(Color.blue.toStr,   "#0000ff")
    verifyEq(Color.orange.toStr, "#ffa500")
  }

  Void testToCss()
  {
    verifyEq(Color(0xaabbcc).toCss, "#aabbcc")
    verifyEq(Color(0x40aabbcc,true).toCss, "rgba(170,187,204,0.25)")
  }

  Void testHsv()
  {
    verifyHsv(0x000000, 0f,   0f, 0f)
    verifyHsv(0xffffff, 0f,   0f, 1f)
    verifyHsv(0xff0000, 0f,   1f, 1f)
    verifyHsv(0x00ff00, 120f, 1f, 1f)
    verifyHsv(0x0000ff, 240f, 1f, 1f)
    verifyHsv(0xffff00, 60f,  1f, 1f)
    verifyHsv(0x00ffff, 180f, 1f, 1f)
    verifyHsv(0xff00ff, 300f, 1f, 1f)
    verifyHsv(0x6496c8, 210f, 0.5f,  0.78f)
    verifyHsv(0x32c850, 132f, 0.75f, 0.78f)
  }

  Void verifyHsv(Int rgb, Float h, Float s, Float v)
  {
    c := Color(rgb, false)
    verify(c.h.approx(h, 0.1f))
    verify(c.s.approx(s, 0.01f))
    verify(c.v.approx(v, 0.01f))
    verifyEq(c, Color.makeHsv(c.h, c.s, c.v))
  }

}