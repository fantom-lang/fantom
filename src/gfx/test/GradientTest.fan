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
    verifyGradient("linear(0% 0%, 100% 100%, #abc 0.0, #def 1.0)",
      "0%", "0%", "100%", "100%", [[abc, 0f], [def, 1f]])

    // implicit percentage stops x2
    verifyGradient("linear(0% 0%, 100% 100%, #abc, #def)",
      "0%", "0%", "100%", "100%", [[abc, 0f], [def, 1f]])

    // one explilcit, one implicit percentage stops
    verifyGradient("linear(0% 0%, 100% 100%, #abc 0.5, #def)",
      "0%", "0%", "100%", "100%", [[abc, 0.5f], [def, 1f]])

    // implicit percentage stops x3
    verifyGradient("linear(0% 0%, 100% 100%, #abc, #00f, #def)",
      "0%", "0%", "100%", "100%", [[abc, 0f], [blue, 0.5f], [def, 1f]])

    // implicit percentage stops x4
    verifyGradient("linear(0% 0%, 100% 100%, #abc, #00f, #ffff0000, #def)",
      "0%", "0%", "100%", "100%", [[abc, 0f], [blue, 0.33f], [red, 0.66f], [def, 1f]])

    // percentage x, y
    verifyGradient("linear(20% 30%, 100% 100%, #f00, #00f)",
      "20%", "30%", "100%", "100%", [[red, 0f], [blue, 1f]])

    // x, y mixed
    verifyGradient("linear(3px 5%, 11px 100%, #f00, #00f)",
      "3px", "5%", "11px", "100%", [[red, 0f], [blue, 1f]])

    // x, y mixed
    verifyGradient("linear(13% 55px, 83% 75px, #f00, #00f)",
      "13%", "55px", "83%", "75px", [[red, 0f], [blue, 1f]])

    // x, y pixels
    verifyGradient("linear(-3px -2px, 44px 22px, #f00, #00f)",
      "-3px", "-2px", "44px", "22px", [[red, 0f], [blue, 1f]])

    // errors
    verifyEq(Gradient.fromStr("", false), null)
    verifyEq(Gradient.fromStr("linear(3p 4px, 6px 8px, f00, #00f)", false), null)
    verifyErr(ParseErr#) { Gradient.fromStr("line(2)", true) }
    verifyErr(ParseErr#) { Gradient.fromStr("linear(-3px -2px 100 100, #f00, #00f)") }
  }

  Void verifyGradient(Str str, Str x1, Str y1, Str x2, Str y2, Obj[][] stops)
  {
    g := Gradient(str)
    verifyEq(g, Gradient(g.toStr))
    verifyIntUnit(g.x1, g.x1Unit, x1)
    verifyIntUnit(g.y1, g.y1Unit, y1)
    verifyIntUnit(g.x2, g.x2Unit, x2)
    verifyIntUnit(g.y2, g.y2Unit, y2)
    verifyEq(g.stops.size, stops.size)
    g.stops.each |stop, i|
    {
      verifyEq(stop.color, stops[i][0])
      verifyEq(stop.pos,   stops[i][1])
    }
  }

  Void verifyIntUnit(Int v, Unit u, Str str)
  {
    verify(u === Gradient.percent || u === Gradient.pixel)
    verifyEq("$v$u.symbol", str)
  }


}