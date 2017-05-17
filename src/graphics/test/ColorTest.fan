//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 2008  Brian Frank  Creation
//   12 May 2016  Brian Frank  SVG/CSS changes
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
    verifyEq(c.a,  1.0f)
    verifyEq(c.rgb,  0xaabbcc)
    verifyColor(c, 0xaa, 0xbb, 0xcc, 1.0f, "#aabbcc")

    c = Color(0xbbccdd, 0.5f)
    verifyEq(c.rgb,  0xbbccdd)
    verifyEq(c.a, 0.5f)
    verifyColor(c, 0xbb, 0xcc, 0xdd, 0.5f, "rgba(187,204,221,0.5)")

    c = Color.makeRgb(1, 2, 3, 0.4f)
    verifyEq(c.rgb, 0x010203)
    verifyEq(c.a, 0.4f)
    verifyColor(c, 1, 2, 3, 0.4f, "rgba(1,2,3,0.4)")

    c = Color.makeRgb(0x33, 0x22, 0x11)
    verifyEq(c.rgb, 0x332211)
    verifyEq(c.a,  1.0f)
    verifyColor(c, 0x33, 0x22, 0x11, 1.0f, "#332211")
  }

  Void verifyColor(Color c, Int r, Int g, Int b, Float a, Str s)
  {
    verifyEq(c.r, r)
    verifyEq(c.g, g)
    verifyEq(c.b, b)
    verifyEq(c.a, a)
    verifyEq(c.toStr, s)
    verifyEq(c, Color.fromStr(c.toStr))
    verifyEq(c, Buf().writeObj(c).flip.readObj)
    verifyEq(c, Color.makeRgb(r, g, b, a))
  }

  Void testFromStr()
  {
    // named colors
    verifyFromStr("red", Color(0xff0000))
    verifyFromStr("DeepPink", Color(0xff1493))
    verifyFromStr("LIME", Color(0x00ff00))

    // #RGB
    verifyFromStr("#abc", Color(0xaabbcc))
    verifyFromStr("#023", Color(0x002233))
    verifyFromStr("#345", Color(0x334455))

    // #RGBA
    verifyFromStr("#a7b3", Color(0xaa77bb, 0.2f))
    verifyFromStr("#30CF", Color(0x3300cc))

    // #RRGGBB
    verifyFromStr("#a4b5c6", Color(0xa4b5c6))

    // #RRGGBBAA
    verifyFromStr("#dea4b540", Color(0xdea4b5, 0.251f))
    verifyFromStr("#12345678", Color(0x123456, GeomUtil.formatFloat(120f/255f).toFloat))

    // rgb() - CSS4 allows comma or space
    verifyFromStr("rgb(10, 20, 30)", Color(0x0a141e, 1.0f))
    verifyFromStr("rgb(10 20 30)", Color(0x0a141e, 1.0f))
    verifyFromStr("rgb(10%, 20%, 30%)", Color(0x19334c, 1.0f))
    verifyFromStr("rgb(10%  20%  30%)", Color(0x19334c, 1.0f))

    // rgba() - CSS4 allows alpha in rgb and uses rgba as deprecated
    verifyFromStr("rgb(10 , 20 , 30 , 0.5)", Color(0x0a141e, 0.5f))
    verifyFromStr("rgb(10  20  30  50%)", Color(0x0a141e, 0.5f))
    verifyFromStr("rgb(50% 0% 100% 25%)", Color(0x7f00ff, 0.25f))
    verifyFromStr("rgb(50%, 0%, 100%, 0.25)", Color(0x7f00ff, 0.25f))
    verifyFromStr("rgba(10 , 20 , 30 , 0.5)", Color(0x0a141e, 0.5f))
    verifyFromStr("rgba(10  20  30  50%)", Color(0x0a141e, 0.5f))
    verifyFromStr("rgba(50% 0% 100% 25%)", Color(0x7f00ff, 0.25f))
    verifyFromStr("rgba(50%, 0%, 100%, 0.25)", Color(0x7f00ff, 0.25f))

    // hsl()
    verifyFromStr("hsl(120deg 50% 0.75)", Color.makeHsl(120f, 0.5f, 0.75f, 1.0f))
    verifyFromStr("hsl(700, 0.2, 0.3, 0.4)", Color.makeHsl(340f, 0.2f, 0.3f, 0.4f))
    verifyFromStr("hsl(0deg  0.8  70%)", Color.makeHsl(0f, 0.8f, 0.7f, 1f))
    verifyFromStr("hsl(0deg  0.8  70%  50%)", Color.makeHsl(0f, 0.8f, 0.7f, 0.5f))

    // hsla()
    verifyFromStr("hsla(120deg 50% 0.75)", Color.makeHsl(120f, 0.5f, 0.75f, 1.0f))
    verifyFromStr("hsla(700, 0.2, 0.3, 0.4)", Color.makeHsl(340f, 0.2f, 0.3f, 0.4f))
    verifyFromStr("hsla(0deg  0.8  70%  50%)", Color.makeHsl(0f, 0.8f, 0.7f, 0.5f))

    // errors
    verifyEq(Color.fromStr("#bc", false), null)
    verifyErr(ParseErr#) { x := Color.fromStr("abc") }
    verifyErr(ParseErr#) { x := Color.fromStr("#xyz", true) }
  }

  Void verifyFromStr(Str s, Color e)
  {
    a := Color.fromStr(s)
    //echo("-- $s\n   $a\n   $e")
    verifyEq(a, e)
  }

  Void testEquals()
  {
    verifyEq(Color(0xaabbcc), Color(0xaabbcc))
    verifyEq(Color(0xaabbcc, 0.5f), Color(0xaabbcc, 0.5f))
    verifyNotEq(Color(0xaa0bcc), Color(0xaabbcc))
    verifyNotEq(Color(0xaabbcc, 1.0f), Color(0xaabbcc, 0.9f))
  }

  Void testHsl()
  {
    verifyHsl(0x000000, 0f,   0f, 0f)
    verifyHsl(0xffffff, 0f,   0f, 1f)
    verifyHsl(0xff0000, 0f,   1f, 1f)
    verifyHsl(0x00ff00, 120f, 1f, 1f)
    verifyHsl(0x0000ff, 240f, 1f, 1f)
    verifyHsl(0xffff00, 60f,  1f, 1f)
    verifyHsl(0x00ffff, 180f, 1f, 1f)
    verifyHsl(0xff00ff, 300f, 1f, 1f)
    verifyHsl(0x6496c8, 210f, 0.5f,  0.78f)
    verifyHsl(0x32c850, 132f, 0.75f, 0.78f)
  }

  Void verifyHsl(Int rgb, Float h, Float s, Float l)
  {
    c := Color(rgb)
    verify(c.h.approx(h, 0.1f))
    verify(c.s.approx(s, 0.01f))
    verify(c.l.approx(l, 0.01f))
    verifyEq(c, Color.makeHsl(c.h, c.s, c.l))
  }

}

