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
    verifyStroke(Stroke {},
      1f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(Stroke { it.width = 3f },
      3f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(Stroke { it.dash = "3,2" },
      1f, "3,2", StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(Stroke { it.cap = StrokeCap.round },
      1f, null, StrokeCap.round, StrokeJoin.miter)

    verifyStroke(Stroke { it.join = StrokeJoin.radius },
      1f, null, StrokeCap.butt, StrokeJoin.radius)

    verifyStroke(Stroke(2f),
      2f, null, StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(Stroke(3f, "2,1"),
      3f, "2,1", StrokeCap.butt, StrokeJoin.miter)

    verifyStroke(Stroke(3f, "2,1", StrokeCap.square),
      3f, "2,1", StrokeCap.square, StrokeJoin.miter)

    verifyStroke(Stroke(3f, "2,1", StrokeCap.square, StrokeJoin.bevel),
      3f, "2,1", StrokeCap.square, StrokeJoin.bevel)

    verifyErr(ParseErr#) { x := Stroke.fromStr("", true) }
    verifyErr(ParseErr#) { x := Stroke.fromStr("notAColor", true) }
    verifyErr(ParseErr#) { x := Stroke.fromStr("notAColor round", true) }
  }

  Void verifyStroke(Stroke s, Float w, Str? dash, StrokeCap cap, StrokeJoin join)
  {
    //echo("=== $s")
    //echo("    " + Stroke.fromStr(s.toStr))

    verifyEq(s.width, w)
    verifyEq(s.dash,  dash)
    verifyEq(s.cap,   cap)
    verifyEq(s.join,  join)

    verifyEq(s, Stroke { it.width = w; it.dash = dash; it.cap = cap; it.join = join })
    verifyEq(s, Stroke(w, dash, cap, join))
    verifyNotEq(s, Stroke(123f, dash, cap, join))
    verifyNotEq(s, Stroke(w, "8,9", cap, join))
    verifyNotEq(s, Stroke(w, dash, cap == StrokeCap.round ? StrokeCap.square : StrokeCap.round, join))
    verifyNotEq(s, Stroke(w, dash, cap, join == StrokeJoin.radius ? StrokeJoin.bevel : StrokeJoin.radius))

    verifyEq(s.isNone, s.width == 0f)

    verifyEq(s, Stroke.fromStr(s.toStr))
    verifyEq(s, Buf().writeObj(s).flip.readObj)
  }

}