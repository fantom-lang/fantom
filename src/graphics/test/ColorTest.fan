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
    verifyEq(c.toHexStr, "#abc")
    verifyColor(c, 0xaa, 0xbb, 0xcc, 1.0f, "#abc")

    c = Color(0x123456)
    verifyEq(c.a,  1.0f)
    verifyEq(c.rgb,  0x123456)
    verifyEq(c.toHexStr, "#123456")
    verifyColor(c, 0x12, 0x34, 0x56, 1.0f, "#123456")

    c = Color(0xbbccdd, 0.5f)
    verifyEq(c.rgb,  0xbbccdd)
    verifyEq(c.a, 0.5f)
    verifyEq(c.toHexStr, "#bbccdd7f")
    verifyColor(c, 0xbb, 0xcc, 0xdd, 0.5f, "rgba(187,204,221,0.5)")

    c = Color.makeRgb(1, 2, 3, 0.4f)
    verifyEq(c.rgb, 0x010203)
    verifyEq(c.a, 0.4f)
    verifyEq(c.toHexStr, "#01020366")
    verifyColor(c, 1, 2, 3, 0.4f, "rgba(1,2,3,0.4)")

    c = Color.makeRgb(0x33, 0x22, 0x11)
    verifyEq(c.rgb, 0x332211)
    verifyEq(c.a,  1.0f)
    verifyColor(c, 0x33, 0x22, 0x11, 1.0f, "#321")

    verifySame(Color.fromStr("transparent"), Color.transparent)
    verifyEq(Color.transparent.isTransparent, true)
    verifyEq(Color.transparent.a, 0f)
    verifyEq(Color("red").isTransparent, false)
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
    // echo("-- $s\n   $a\n   $e")
    verifyEq(a, e)

    list := Color.listFromStr("$s,$s , $s")
    verifyEq(list.size, 3)
    verifyEq(list[0], e)
    verifyEq(list[1], e)
    verifyEq(list[2], e)
  }

  Void testListFromStr()
  {
    verifyEq(Color.listFromStr("#abc, red, rgb(128, 0, 0)"),
             Color[Color("#abc"), Color("red"), Color("rgb(128, 0, 0)")])
    verifyEq(Color.listFromStr("rgba(128, 0, 0, 50%), #abc, rgb(128, 0, 0)"),
             Color[Color("rgba(128, 0, 0, 50%)"), Color("#abc"), Color("rgb(128, 0, 0)")])
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
    verifyHsl(0x000000, 0f,   0f, 0f)      // black
    verifyHsl(0xffffff, 0f,   0f, 1f)      // white
    verifyHsl(0xff0000, 0f,   1f, 0.5f)    // red
    verifyHsl(0x00ff00, 120f, 1f, 0.5f)    // lime
    verifyHsl(0x0000ff, 240f, 1f, 0.5f)    // blue
    verifyHsl(0xffff00, 60f,  1f, 0.5f)    // yellow
    verifyHsl(0x00ffff, 180f, 1f, 0.5f)    // cyan
    verifyHsl(0xff00ff, 300f, 1f, 0.5f)    // magenta
    verifyHsl(0xbfbfbf, 0f,   0f, 0.749f)  // silver (191,191,191)
    verifyHsl(0x808080, 0f,   0f, 0.501f)  // gray   (128,128,128)
    verifyHsl(0x800000, 0f,   1f, 0.25f)   // maroon (128,0,0)
    verifyHsl(0x808000, 60f,  1f, 0.25f)   // olive  (128,128,0)
    verifyHsl(0x008000, 120f, 1f, 0.25f)   // green  (0,128,0)
    verifyHsl(0x800080, 300f, 1f, 0.25f)   // purple (128,0,128)
    verifyHsl(0x008080, 180f, 1f, 0.25f)   // teal   (0,128,128)
    verifyHsl(0x000080, 240f, 1f, 0.25f)   // navy   (0,0,128)

    verifyHsl(0x32c850, 132f,     0.60f,  0.490f)  // (50,200,80)
    verifyHsl(0x6496c8, 210f,     0.476f, 0.588f)  // (100,150,200)
    verifyHsl(0x7e22ce, 272.093f, 0.716f, 0.470f)  // (126, 34, 206)
    verifyHsl(0xfcd34d, 45.942f,  0.967f, 0.645f)  // (252, 211, 77)

    // l=100% is always #fff and so we lose hue/sat on roundtrip to rgb
    verifyHsl(Color("hsl(240 0.4 1)"), 0f, 0f, 1f)
  }

  Void verifyHsl(Obj obj, Float h, Float s, Float l)
  {
    c := obj as Color ?: Color.make(obj)
    verify(c.h.approx(h, 0.001f))
    verify(c.s.approx(s, 0.001f))
    verify(c.l.approx(l, 0.001f))
    verifyEq(c, Color.makeHsl(c.h, c.s, c.l))
  }

//////////////////////////////////////////////////////////////////////////
// Interpolate RGB
//////////////////////////////////////////////////////////////////////////

  Void testInterpolateRgb()
  {
    a := Color("#123")
    b := Color("#cba")
    verifyInterpolateRgb(a, b, -1f,   "rgb(0 0 0)")
    verifyInterpolateRgb(a, b, -0.2f, "rgb(0 3 27)")
    verifyInterpolateRgb(a, b, 0f,    "rgb(17 34 51)")
    verifyInterpolateRgb(a, b, 0.25f, "rgb(63 72 80)")
    verifyInterpolateRgb(a, b, 0.5f,  "rgb(110 110 110)")
    verifyInterpolateRgb(a, b, 0.75f, "rgb(157 148 140)")
    verifyInterpolateRgb(a, b, 1.0f,  "rgb(204 187 170)")
    verifyInterpolateRgb(a, b, 1.2f,  "rgb(241 217 193)")
    verifyInterpolateRgb(a, b, 2f,    "rgb(255 255 255)")

    a = Color("rgba(200 70 30 0.9)")
    b = Color("rgba(250 20 90 0.1)")
    verifyInterpolateRgb(a, b, -1f,   "rgba(150 120 0 1.0)")
    verifyInterpolateRgb(a, b, -0.2f, "rgba(190 80 18 1.0)")
    verifyInterpolateRgb(a, b, 0f,    "rgba(200 70 30 0.9)")
    verifyInterpolateRgb(a, b, 0.25f, "rgba(212 57 45 0.7)")
    verifyInterpolateRgb(a, b, 0.5f,  "rgba(225 45 60 0.5)")
    verifyInterpolateRgb(a, b, 0.75f, "rgba(237 32 75 0.3)")
    verifyInterpolateRgb(a, b, 1.0f,  "rgba(250 20 90 0.1)")
    verifyInterpolateRgb(a, b, 1.2f,  "rgba(255 10 102 0.0)")
    verifyInterpolateRgb(a, b, 2f,    "rgba(255 0 150 0.0)")
  }

  Void verifyInterpolateRgb(Color a, Color b, Float t, Str expected)
  {
    x := Color.interpolateRgb(a, b, t)
    //echo("-- $a, $b  $t => $x ?= $expected => " + (x == Color(expected)))
    verifyRbgEq(x, Color(expected))
  }

//////////////////////////////////////////////////////////////////////////
// Interpolote HSL
//////////////////////////////////////////////////////////////////////////

  Void testInterpolateHsl()
  {
    a := Color("hsl(200 0.5 0.9)")
    b := Color("hsl(20 1 0.1)")
    verifyInterpolateHsl(a, b, -1f,   "hsl(360 0 1)")
    verifyInterpolateHsl(a, b, -0.2f, "hsl(236 0.4 1)")
    verifyInterpolateHsl(a, b, 0f,    "hsl(200 0.5 0.9)")
    verifyInterpolateHsl(a, b, 0.25f, "hsl(155 0.625 0.7)")
    verifyInterpolateHsl(a, b, 0.5f,  "hsl(110 0.75 0.5)")
    verifyInterpolateHsl(a, b, 0.75f, "hsl(65 0.875 0.3)")
    verifyInterpolateHsl(a, b, 1.0f,  "hsl(20 1 0.1)")
    verifyInterpolateHsl(a, b, 1.2f,  "hsl(0 1 0)")
    verifyInterpolateHsl(a, b, 2f,    "hsl(0 1 0)")
  }

  Void verifyInterpolateHsl(Color a, Color b, Float t, Str expected)
  {
    r := Color.interpolateHsl(a, b, t)
    e := Color(expected)
    //echo("-- $t")
    //echo("   ${hslStr(r)} // result")
    //echo("   ${hslStr(e)} // expected")
    verifyHslEq(r, e)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static Str hslStr(Color c)
  {
    "hsl(" + GeomUtil.formatFloat(c.h) + " " +
             GeomUtil.formatFloat(c.s) + " " +
             GeomUtil.formatFloat(c.l) + " " +
             GeomUtil.formatFloat(c.a) + ")"
  }

  Void verifyRbgEq(Color a, Color b)
  {
    verifyEq(a.r, b.r)
    verifyEq(a.g, b.g)
    verifyEq(a.b, b.b)
    verify(a.a.approx(b.a))
  }

  Void verifyHslEq(Color a, Color b)
  {
    verify(a.h.approx(b.h, 2f))
    verify(a.s.approx(b.s, 0.05f))
    verify(a.l.approx(b.l, 0.05f))
    verify(a.a.approx(b.a))
  }

}

