//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Mar 2022  Brian Frank  Creation
//

**
** StrokeTest
**
@Js
class StrokeTest : Test
{

  Void testMake()
  {
    verifyStroke(StyledStroke {},
      Color.black, 1f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke { it.color = Color("blue") },
      Color("blue"), 1f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke { it.width = 3f },
      Color.black, 3f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke { it.dash = "3,2" },
      Color.black, 1f, "3,2", StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke { it.cap = StrokeCap.round },
      Color.black, 1f, null, StrokeCap.round, StrokeJoin.miter)

    verifyStroke(StyledStroke { it.join = StrokeJoin.radius },
      Color.black, 1f, null, StrokeCap.butt, StrokeJoin.radius)

    verifyStroke(StyledStroke(Color("red")),
      Color("red"), 1f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke(Color("red"), 2f),
      Color("red"), 2f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke(Color("red"), 3f, "2,1"),
      Color("red"), 3f, "2,1", StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(StyledStroke(Color("red"), 3f, "2,1", StrokeCap.square),
      Color("red"), 3f, "2,1", StrokeCap.square, StrokeJoin.miter)

    verifyStroke(StyledStroke(Color("red"), 3f, "2,1", StrokeCap.square, StrokeJoin.bevel),
      Color("red"), 3f, "2,1", StrokeCap.square, StrokeJoin.bevel)

    verifyErr(ParseErr#) { x := StyledStroke.fromStr("", true) }
    verifyErr(ParseErr#) { x := StyledStroke.fromStr("notAColor", true) }
    verifyErr(ParseErr#) { x := StyledStroke.fromStr("notAColor round", true) }
  }

  Void verifyStroke(StyledStroke s, Color c, Float w, Str? dash, StrokeCap cap, StrokeJoin join)
  {
    // echo("=== $s")
    // echo("    " + StyledStroke.fromStr(s.toStr))

    verifyEq(s.color, c)
    verifyEq(s.width, w)
    verifyEq(s.dash,  dash)
    verifyEq(s.cap,   cap)
    verifyEq(s.join,  join)

    verifyEq(s.isColorStroke, false)
    verifyEq(s.isStyledStroke, true)
    verifySame(s.asColorStroke, s.color)
    verifySame(s.asStyledStroke, s)

    verifyEq(s, StyledStroke { it.color = c; it.width = w; it.dash = dash; it.cap = cap; it.join = join })
    verifyEq(s, StyledStroke(c, w, dash, cap, join))
    verifyNotEq(s, StyledStroke(Color("#abc"), w, dash, cap, join))
    verifyNotEq(s, StyledStroke(c, 123f, dash, cap, join))
    verifyNotEq(s, StyledStroke(c, w, "8,9", cap, join))
    verifyNotEq(s, StyledStroke(c, w, dash, cap == StrokeCap.round ? StrokeCap.square : StrokeCap.round, join))
    verifyNotEq(s, StyledStroke(c, w, dash, cap, join == StrokeJoin.radius ? StrokeJoin.bevel : StrokeJoin.radius))

    verifyEq(s, StyledStroke.fromStr(s.toStr))
    verifyEq(s, Buf().writeObj(s).flip.readObj)
  }

}