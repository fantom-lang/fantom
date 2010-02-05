//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 08  Brian Frank  Creation
//

**
** GeomTest
**
@Js
class GeomTest : Test
{

  Void testPoint()
  {
    verifyEq(Point.defVal, Point(0, 0))
    verifyEq(Point#.make, Point(0, 0))

    verifyEq(Point(3, 4), Point(3, 4))
    verifyNotEq(Point(3, 9), Point(3, 4))
    verifyNotEq(Point(9, 4), Point(3, 4))

    verifyEq(Point.fromStr("4,-2"), Point(4, -2))
    verifyEq(Point.fromStr("33 , 44"), Point(33, 44))
    verifyEq(Point.fromStr("x,-2", false), null)
    verifyErr(ParseErr#) { Point.fromStr("x,-2") }
    verifyErr(ParseErr#) { Point.fromStr("x,-2", true) }

    verifySer(Point(0, 1))
    verifySer(Point(-99, -505))
  }

  Void testSize()
  {
    verifyEq(Size.defVal, Size(0, 0))
    verifyEq(Size#.make, Size(0, 0))

    verifyEq(Size(3, 4), Size(3, 4))
    verifyNotEq(Size(3, 9), Size(3, 4))
    verifyNotEq(Size(9, 4), Size(3, 4))

    verifyEq(Size.fromStr("4,-2"), Size(4, -2))
    verifyEq(Size.fromStr("-33 , 60"), Size(-33, 60))
    verifyEq(Size.fromStr("x,-2", false), null)
    verifyErr(ParseErr#) { Size.fromStr("x,-2") }
    verifyErr(ParseErr#) { Size.fromStr("x,-2", true) }

    verifySer(Size(0, 1))
    verifySer(Size(-99, -505))
  }

  Void testRect()
  {
    verifyEq(Rect.defVal, Rect(0, 0, 0, 0))
    verifyEq(Rect#.make, Rect(0, 0, 0, 0))

    verifyEq(Rect(1, 2, 3, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(0, 2, 3, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 0, 3, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 2, 0, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 2, 3, 0), Rect(1, 2, 3, 4))

    r := Rect(2,2,6,6)
    verify(r.contains(4,4))
    verify(r.contains(2,4))
    verify(r.contains(4,2))
    verify(r.contains(2,2))
    verify(r.contains(8,8))
    verify(!r.contains(1,1))
    verify(!r.contains(2,9))
    verify(!r.contains(1,5))

    verifyEq(Rect.fromStr("3,4,5,6"), Rect(3,4,5,6))
    verifyEq(Rect.fromStr("-1 , -2, -3  , -4"), Rect(-1,-2,-3,-4))
    verifyEq(Rect.fromStr("3,4,5", false), null)
    verifyErr(ParseErr#) { Rect.fromStr("3,4,x,6") }
    verifyErr(ParseErr#) { Rect.fromStr("", true) }

    verifySer(Rect(1, 2, 3, 4))
    verifySer(Rect(-1, 2, -3, 4))
  }

  Void testInsets()
  {
    verifyEq(Insets(1, 2, 3, 4), Insets(1, 2, 3, 4))
    verifyEq(Insets(1, 2, 3, 4).top,    1)
    verifyEq(Insets(1, 2, 3, 4).right,  2)
    verifyEq(Insets(1, 2, 3, 4).bottom, 3)
    verifyEq(Insets(1, 2, 3, 4).left,   4)
    verifyEq(Insets(1, 2, 3, 4).toSize, Size(6,4))
    verifyNotEq(Insets(0, 2, 3, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 0, 3, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 2, 0, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 2, 3, 0), Insets(1, 2, 3, 4))

    verifyEq(Insets(1), Insets(1,1,1,1))
    verifyEq(Insets(1,2), Insets(1,2,1,2))
    verifyEq(Insets(1,2,3), Insets(1,2,3,2))

    verifyEq(Insets.fromStr("3,4,5,6"), Insets(3,4,5,6))
    verifyEq(Insets.fromStr("10"), Insets(10,10,10,10))
    verifyEq(Insets.fromStr("-1 , -2, -3  , -4"), Insets(-1,-2,-3,-4))
    verifyEq(Insets.fromStr("3,4,5", false), null)
    verifyErr(ParseErr#) { Insets.fromStr("3,4,x,6") }
    verifyErr(ParseErr#) { Insets.fromStr("", true) }

    verifySer(Insets(1, 2, 3, 4))
    verifySer(Insets(-1, 2, -3, 4))
  }

  Void testHints()
  {
    verifyEq(Hints.defVal, Hints(null, null))
    verifyEq(Hints#.make, Hints(null, null))

    verifyEq(Hints(3, null), Hints(3, null))
    verifyEq(Hints(null, 3), Hints(null, 3))
    verifyEq(Hints(4, 5), Hints(4, 5))
    verifyNotEq(Hints(4, null), Hints(4, 5))
    verifyNotEq(Hints(null, 5), Hints(4, 5))
    verifyNotEq(Hints(4, 6), Hints(4, 5))

    size := Size(3, 4)
    verifyEq(Hints(null, null) + size, Hints(null, null))
    verifyEq(Hints(5, null) + size, Hints(8, null))
    verifyEq(Hints(null, 5) + size, Hints(null, 9))
    verifyEq(Hints(11, 5) + size, Hints(14, 9))

    verifyEq(Hints(null, null) - size, Hints(null, null))
    verifyEq(Hints(5, null) - size, Hints(2, null))
    verifyEq(Hints(null, 7) - size, Hints(null, 3))
    verifyEq(Hints(11, 13) - size, Hints(8, 9))
  }

  Void verifySer(Obj obj)
  {
    //echo("-- " + Buf.make.writeObj(obj).flip.readAllStr)
    x := Buf.make.writeObj(obj).flip.readObj
    verifyEq(obj, x)
  }


}