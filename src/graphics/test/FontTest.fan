//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 2008  Brian Frank  Creation
//   12 May 2016  Brian Frank  SVG/CSS changes
//

**
** FontTest
**
@Js
class FontTest : Test
{

  Void testWeight()
  {
    verifyEq(FontWeight.fromNum(400), FontWeight.normal)
    verifyEq(FontWeight.fromNum(700), FontWeight.bold)
    verifyEq(FontWeight.fromNum(99, false), null)
    verifyErr(ArgErr#) { FontWeight.fromNum(-1) }
    verifyErr(ArgErr#) { FontWeight.fromNum(0, true) }

    verifyEq(FontWeight.decode("300"), FontWeight.light)
    verifyEq(FontWeight.decode("400"), FontWeight.normal)
    verifyEq(FontWeight.decode("normal"), FontWeight.normal)
    verifyEq(FontWeight.decode("bold"), FontWeight.bold)
    verifyEq(FontWeight.decode("900"), FontWeight.black)
    verifyEq(FontWeight.decode("foo", false), null)
    verifyEq(FontWeight.decode("555", false), null)
    verifyErr(ArgErr#) { FontWeight.decode("badone") }
    verifyErr(ArgErr#) { FontWeight.decode("123", true) }
  }

  Void testMake()
  {
    verifyFont(Font { names = ["Arial"]; size = 10f },
      ["Arial"], 10f, FontWeight.normal, FontStyle.normal, "10pt Arial")

    verifyFont(Font { names = ["Arial", "sans-serif"]; size = 11f; weight= FontWeight.bold },
      ["Arial", "sans-serif"], 11f, FontWeight.bold, FontStyle.normal, "700 11pt Arial,sans-serif")

    verifyFont(Font { names = ["Courier", "monospace"]; size = 12f; style= FontStyle.italic },
      ["Courier", "monospace"], 12f, FontWeight.normal, FontStyle.italic, "italic 12pt Courier,monospace")

    verifyFont(Font { names = ["Courier", "monospace"]; size = 12f; weight= FontWeight.light; style= FontStyle.italic },
      ["Courier", "monospace"], 12f, FontWeight.light, FontStyle.italic, "italic 300 12pt Courier,monospace")

    verifyFont(Font.fromStr("12pt Courier, monospace"),
      ["Courier", "monospace"], 12f, FontWeight.normal, FontStyle.normal, "12pt Courier,monospace")

    verifyFont(Font.fromStr("normal 12pt Courier, monospace"),
      ["Courier", "monospace"], 12f, FontWeight.normal, FontStyle.normal, "12pt Courier,monospace")

    verifyFont(Font.fromStr("normal bold 12pt Courier, monospace"),
      ["Courier", "monospace"], 12f, FontWeight.bold, FontStyle.normal, "700 12pt Courier,monospace")

    verifyFont(Font.fromStr("bold 12pt Consolas, Courier, monospace"),
      ["Consolas", "Courier", "monospace"], 12f, FontWeight.bold, FontStyle.normal, "700 12pt Consolas,Courier,monospace")

    verifyErr(ParseErr#) { x := Font.fromStr("10 Arial") }
    verifyErr(ParseErr#) { x := Font.fromStr("", true) }
  }

  Void verifyFont(Font f, Str[] names, Float size, FontWeight weight, FontStyle style, Str str)
  {
    //echo("=== $f")
    //echo("    " + Font.fromStr(f.toStr))

    verifyEq(f.names, names)
    verifyEq(f.size, size)
    verifyEq(f.weight, weight)
    verifyEq(f.style, style)
    verifyEq(f.toStr, str)

    verifyEq(f, Font { it.names = names; it.size = size; it.weight = weight; it.style = style })
    verifyNotEq(f, Font { it.names = names.dup.add("x"); it.size = size; it.weight = weight; it.style = style })
    verifyNotEq(f, Font { it.names = names; it.size = size+1; it.weight = weight; it.style = style })
    verifyNotEq(f, Font { it.names = names; it.size = size; it.weight = FontWeight.fromNum(weight.num+100); it.style = style })
    verifyNotEq(f, Font { it.names = names; it.size = size; it.weight = weight; it.style = FontStyle.vals[style.ordinal+1] })

    verifyEq(f, Font.fromStr(f.toStr))
    verifyEq(f, Buf().writeObj(f).flip.readObj)
  }

  Void testNormalize()
  {
    ["Helvetica", "Something,Helvetica"].each |x|
    {
      verifyNormalize("12pt $x", "12pt Helvetica")
      verifyNormalize("14pt $x", "14pt Helvetica")
      verifyNormalize("oblique 14pt $x", "italic 14pt Helvetica")
      verifyNormalize("italic 14pt $x", "italic 14pt Helvetica")
      verifyNormalize("bold 11pt $x", "700 11pt Helvetica")
      verifyNormalize("300 8pt $x", "8pt Helvetica")
      verifyNormalize("500 8pt $x", "700 8pt Helvetica")
      verifyNormalize("600 8pt $x", "700 8pt Helvetica")
      verifyNormalize("900 8pt $x", "700 8pt Helvetica")
      verifyNormalize("italic 600 8pt $x", "italic 700 8pt Helvetica")
      verifyNormalize("italic 300 8pt $x", "italic 8pt Helvetica")
    }

    verifyNormalize("12pt Roboto Mono", "12pt Roboto Mono")
    verifyNormalize("bold 12pt Roboto Mono", "12pt Roboto Mono")
  }

  Void verifyNormalize(Str s, Str expected)
  {
    f := Font(s)
    actual := f.normalize
    //echo("-- $f")
    //echo("   $actual")
    verifyEq(actual.toStr, expected)
  }

  Void testProps()
  {
    verifyProps("12pt Helvetica", ["font-family":"Helvetica", "font-size":"12pt"])
    verifyProps("bold 12pt Helvetica", ["font-family":"Helvetica", "font-size":"12pt", "font-weight":"700"])
    verifyProps("300 12pt Helvetica", ["font-family":"Helvetica", "font-size":"12pt", "font-weight":"300"])
    verifyProps("italic 12pt Helvetica", ["font-family":"Helvetica", "font-size":"12pt", "font-style":"italic"])
    verifyProps("italic bold 11pt Helvetica", ["font-family":"Helvetica", "font-size":"11pt", "font-weight":"700", "font-style":"italic"])
    verifyProps("italic 800 8pt Helvetica", ["font-family":"Helvetica", "font-size":"8pt", "font-weight":"800", "font-style":"italic"])
  }

  Void verifyProps(Str str, Str:Str props)
  {
    f := Font(str)
    verifyEq(f.toProps, props)
    verifyEq(Font.fromProps(props), f)
  }
}