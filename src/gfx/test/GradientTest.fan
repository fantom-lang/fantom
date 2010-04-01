//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Mar 10  Brian Frank  Creation
//

**
** GradientTest
**
@Js
class GradientTest : Test
{
  const Color abc  := Color("#abc")
  const Color def  := Color("#def")
  const Color red  := Color.red
  const Color blue := Color.blue

  Void test()
  {
    // explicit percentage stops
    verifyGradient("linear(0% 0%, #abc 0%, #def 100%)",
      "0%", "0%", null, [[abc, "0%"], [def, "100%"]])

    // explicit pixel stops
    verifyGradient("linear(0% 0%, #aabbcc 3px, #def 22px)",
      "0%", "0%", null, [[abc, "3px"], [def, "22px"]])

    // implicit percentage stops x2
    verifyGradient("linear(0% 0%, #abc, #def)",
      "0%", "0%", null, [[abc, "0%"], [def, "100%"]])

    // one explilcit, one implicit percentage stops
    verifyGradient("linear(0% 0%, #abc 12px, #def)",
      "0%", "0%", null, [[abc, "12px"], [def, "100%"]])

    // implicit percentage stops x3
    verifyGradient("linear(0% 0%, #abc, #00f, #def)",
      "0%", "0%", null, [[abc, "0%"], [blue, "50%"], [def, "100%"]])

    // implicit percentage stops x4
    verifyGradient("linear(0% 0%, #abc, #00f, #ffff0000, #def)",
      "0%", "0%", null, [[abc, "0%"], [blue, "33%"], [red, "66%"], [def, "100%"]])

    // percentage x, y
    verifyGradient("linear(20% 30%, #f00, #00f)",
      "20%", "30%", null, [[red, "0%"], [blue, "100%"]])

    // x, y mixed
    verifyGradient("linear(3px 5%, #f00, #00f)",
      "3px", "5%", null, [[red, "0%"], [blue, "100%"]])

    // x, y mixed
    verifyGradient("linear(13% 55px, #f00, #00f)",
      "13%", "55px", null, [[red, "0%"], [blue, "100%"]])

    // x, y pixels
    verifyGradient("linear(-3px -2px, #f00, #00f)",
      "-3px", "-2px", null, [[red, "0%"], [blue, "100%"]])

    // x, y pixels and angle
    verifyGradient("linear(-3px -2px -166deg, #f00, #00f)",
      "-3px", "-2px", -166, [[red, "0%"], [blue, "100%"]])

    // try out the combos of named positionals
    posExpected := ["0%", "50%", "100%"]
    ["top", "center", "bottom"].each |posy, yi|
    {
      ["left", "center", "right"].each |posx, xi|
      {
        // if posx is center it is implied
        if (posx == "center")
          verifyGradient("$posy, #f00, #00f",
            posExpected[xi], posExpected[yi], null, [[red, "0%"], [blue, "100%"]])

        // if posy is center it is implied
        if (posy == "center")
          verifyGradient("$posx, #f00, #00f",
            posExpected[xi], posExpected[yi], null, [[red, "0%"], [blue, "100%"]])

        // x y
        verifyGradient("$posx $posy, #f00, #00f",
          posExpected[xi], posExpected[yi], null, [[red, "0%"], [blue, "100%"]])

        // y x
        verifyGradient("linear($posy $posx, #f00, #00f)",
          posExpected[xi], posExpected[yi], null, [[red, "0%"], [blue, "100%"]])

        // x y angle
        verifyGradient("linear($posx $posy 45deg, #f00, #00f)",
          posExpected[xi], posExpected[yi], 45, [[red, "0%"], [blue, "100%"]])

        // y x angle
        verifyGradient("linear($posy $posx -32deg, #f00 3px, #abc 10px, #00f 22px)",
          posExpected[xi], posExpected[yi], -32, [[red, "3px"], [abc, "10px"], [blue, "22px"]])
      }
    }

    // errors
    verifyEq(Gradient.fromStr("", false), null)
    verifyEq(Gradient.fromStr("linear(top top, #f00, #00f)", false), null)
    verifyEq(Gradient.fromStr("linear(3p 4px, f00, #00f)", false), null)
    verifyErr(ParseErr#) { Gradient.fromStr("line(2)", true) }
    verifyErr(ParseErr#) { Gradient.fromStr("linear(-3px -2px -166de, #f00, #00f)") }
  }

  Void verifyGradient(Str str, Str x, Str y, Int? angle, Obj[][] stops)
  {
    g := Gradient(str)
    verifyEq(g, Gradient(g.toStr))
    verifyIntUnit(g.x, g.xUnit, x)
    verifyIntUnit(g.y, g.yUnit, y)
    verifyEq(g.angle, angle)
    verifyEq(g.stops.size, stops.size)
    g.stops.each |stop, i|
    {
      verifyEq(stop.color, stops[i][0])
      verifyIntUnit(stop.pos, stop.unit, stops[i][1])
    }
  }

  Void verifyIntUnit(Int v, Unit u, Str str)
  {
    verify(u === Gradient.percent || u === Gradient.pixel)
    verifyEq("$v$u.symbol", str)
  }


}