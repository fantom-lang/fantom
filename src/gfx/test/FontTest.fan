//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** FontTest
**
@Js
class FontTest : Test
{

  Void testMake()
  {
    verifyFont(Font { name = "Arial"; size = 10 },
      "Arial", 10, false, false, "10pt Arial")

    verifyFont(Font { name = "Arial Special"; size = 10; bold = true},
      "Arial Special", 10, true, false, "bold 10pt Arial Special")

    verifyFont(Font.makeFields("Courier", 11, false, true),
      "Courier", 11, false, true, "italic 11pt Courier")

    verifyFont(Font.makeFields("Courier", 16, true, true),
      "Courier", 16, true, true, "bold italic 16pt Courier")

    verifyEq(Font.fromStr("22pt Arial"), Font.makeFields("Arial", 22))
    verifyEq(Font.fromStr("bold 22pt Foo Bar"), Font.makeFields("Foo Bar", 22, true))
    verifyEq(Font.fromStr("italic 5pt Arial"), Font.makeFields("Arial", 5, false, true))
    verifyEq(Font.fromStr("bold italic 10pt Aa Bb"), Font.makeFields("Aa Bb", 10, true, true))
    verifyEq(Font.fromStr("Arial", false), null)
    verifyErr(ParseErr#) { Font.fromStr("10 Arial") }
    verifyErr(ParseErr#) { Font.fromStr("", true) }
  }

  Void verifyFont(Font f, Str name, Int size, Bool bold, Bool italic, Str str)
  {
    verifyEq(f.name, name)
    verifyEq(f.size, size)
    verifyEq(f.bold, bold)
    verifyEq(f.italic, italic)
    verifyEq(f.toStr, str)

    verifyEq(f, Font { it.name = name; it.size = size; it.bold = bold; it.italic = italic })
    verifyNotEq(f, Font { it.name = name+"x"; it.size = size; it.bold = bold; it.italic = italic })
    verifyNotEq(f, Font { it.name = name; it.size = size+1; it.bold = bold; it.italic = italic })
    verifyNotEq(f, Font { it.name = name; it.size = size; it.bold = !bold; it.italic = italic })
    verifyNotEq(f, Font { it.name = name; it.size = size; it.bold = bold; it.italic = !italic })

    verifyEq(f, Font.fromStr(f.toStr))
    verifyEq(f, Buf().writeObj(f).flip.readObj)
  }

}