//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 2008  Brian Frank  Creation (gfx version)
//  12 May 2016  Brian Frank  SVG/CSS changes
//

**
** GeomTest
**
@Js
class GeomTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Spilt
//////////////////////////////////////////////////////////////////////////

  Void testSplit()
  {
    verifyEq(GeomUtil.split("a"), ["a"])
    verifyEq(GeomUtil.split("a,b"), ["a","b"])
    verifyEq(GeomUtil.split("a b"), ["a", "b"])
    verifyEq(GeomUtil.split("a, b"), ["a", "b"])
    verifyEq(GeomUtil.split("a  b"), ["a", "b"])
  }

//////////////////////////////////////////////////////////////////////////
// Point
//////////////////////////////////////////////////////////////////////////

  Void testPoint()
  {
    verifyEq(Point.defVal, Point(0, 0))
    verifyEq(Point#.make, Point(0, 0))

    verifyEq(Point(3, 4), Point(3, 4))
    verifyEq(Point(3, 4), Point(3f, 4f))
    verifyEq(Point(3.5f, 4.5f), Point(3.5f, 4.5f))
    verifyNotEq(Point(3, 9), Point(3, 4))
    verifyNotEq(Point(9, 4), Point(3, 4))

    verifyEq(Point(2, 3).toStr, "2 3")
    verifyEq(Point(2.5f, 0.4f).toStr, "2.5 0.4")

    verifyEq(Point.fromStr("4,-2"), Point(4, -2))
    verifyEq(Point.fromStr("33 , 44"), Point(33, 44))
    verifyEq(Point.fromStr("x,-2", false), null)
    verifyErr(ParseErr#) { x := Point.fromStr("x,-2") }
    verifyErr(ParseErr#) { x := Point.fromStr("x,-2", true) }

    verifySer(Point(0, 1))
    verifySer(Point(-99, -505))
  }

//////////////////////////////////////////////////////////////////////////
// Size
//////////////////////////////////////////////////////////////////////////

  Void testSize()
  {
    verifyEq(Size.defVal, Size(0, 0))
    verifyEq(Size#.make, Size(0, 0))

    verifyEq(Size(3, 4), Size(3, 4))
    verifyEq(Size(3, 4), Size(3f, 4f))
    verifyEq(Size(3.5f, 4.5f), Size(3.5f, 4.5f))
    verifyNotEq(Size(3, 9), Size(3, 4))
    verifyNotEq(Size(9, 4), Size(3, 4))

    verifyEq(Size(2, 3).toStr, "2 3")
    verifyEq(Size(2.5f, 0.4f).toStr, "2.5 0.4")

    verifyEq(Size.fromStr("4,-2"), Size(4, -2))
    verifyEq(Size.fromStr("-33 , 60"), Size(-33, 60))
    verifyEq(Size.fromStr("x,-2", false), null)
    verifyErr(ParseErr#) { x := Size.fromStr("x,-2") }
    verifyErr(ParseErr#) { x := Size.fromStr("x,-2", true) }

    verifySer(Size(0, 1))
    verifySer(Size(-99, -505))
  }

//////////////////////////////////////////////////////////////////////////
// Rect
//////////////////////////////////////////////////////////////////////////

  Void testRect()
  {
    verifyEq(Rect.defVal, Rect(0, 0, 0, 0))
    verifyEq(Rect#.make, Rect(0, 0, 0, 0))

    r := Rect(1.2f, 2f, 3.5f, 4f)
    verifyEq(r.x, 1.2f)
    verifyEq(r.y, 2f)
    verifyEq(r.w, 3.5f)
    verifyEq(r.h, 4f)

    verifyEq(Rect(1, 2, 3, 4), Rect(1, 2, 3, 4))
    verifyEq(Rect(1, 2, 3, 4), Rect(1f, 2f, 3f, 4f))
    verifyNotEq(Rect(0, 2, 3, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 0, 3, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 2, 0, 4), Rect(1, 2, 3, 4))
    verifyNotEq(Rect(1, 2, 3, 0), Rect(1, 2, 3, 4))

    verifyEq(Rect(1, 2, 3, 4).toStr, "1 2 3 4")
    verifyEq(Rect(1.5f, 2.5f, 3f, 4.2f).toStr, "1.5 2.5 3 4.2")

    // contains
    r = Rect(2,2,6,6)
    verify(r.contains(Point(4,4)))
    verify(r.contains(Point(2,4)))
    verify(r.contains(Point(4,2)))
    verify(r.contains(Point(2,2)))
    verify(r.contains(Point(8,8)))
    verify(!r.contains(Point(1,1)))
    verify(!r.contains(Point(2,9)))
    verify(!r.contains(Point(1,5)))

    // intersection
    verifyIntersection(Rect(0, 5, 10, 10), Rect(5, 10, 15, 10), Rect(5, 10, 5, 5))
    verifyIntersection(Rect(0, 5, 15, 15), Rect(5, 10, 20, 5), Rect(5, 10, 10, 5))
    verifyIntersection(Rect(10, 0, 5, 20), Rect(5, 10, 20, 5), Rect(10, 10, 5, 5))
    verifyIntersection(Rect(0, 0, 20, 20), Rect(5, 5, 5, 10), Rect(5, 5, 5, 10))
    verifyIntersection(Rect(0, 0, 15, 10), Rect(0, 5, 15, 15), Rect(0, 5, 15, 5))
    verifyIntersection(Rect(0, 0, 5, 5), Rect(10, 10, 5, 5), Rect.defVal)
    verifyIntersection(Rect(5, 5, 5, 5), Rect(0, 10, 15, 5), Rect.defVal)
    verifyIntersection(Rect(0, 0, 15, 5), Rect(0, 5, 15, 15), Rect.defVal)

    // union
    verifyUnion(Rect(0, 0, 5, 5), Rect(10, 15, 10, 5), Rect(0, 0, 20, 20))
    verifyUnion(Rect(10, 5, 5, 20), Rect(0, 10, 25, 5), Rect(0, 5, 25, 20))
    verifyUnion(Rect(0, 10, 10, 5), Rect(5, 20, 15, 5), Rect(0, 10, 20, 15))
    verifyUnion(Rect(5, 10, 5, 5), Rect(15, 5, 5, 20), Rect(5, 5, 15, 20))

    verifyEq(Rect.fromStr("3,4,5,6"), Rect(3,4,5,6))
    verifyEq(Rect.fromStr("-1 , -2, -3  , -4"), Rect(-1,-2,-3,-4))
    verifyEq(Rect.fromStr("3,4,5", false), null)
    verifyErr(ParseErr#) { x := Rect.fromStr("3,4,x,6") }
    verifyErr(ParseErr#) { x := Rect.fromStr("", true) }

    verifySer(Rect(1, 2, 3, 4))
    verifySer(Rect(-1, 2, -3, 4))
  }

  Void verifyIntersection(Rect a, Rect b, Rect r)
  {
    verifyEq(a.intersection(b), r)
    verifyEq(b.intersection(a), r)
    verifyEq(a.intersects(b), r != Rect.defVal)
    verifyEq(b.intersects(a), r != Rect.defVal)
  }

  Void verifyUnion(Rect a, Rect b, Rect r)
  {
    verifyEq(a.union(a), a)
    verifyEq(a.union(b), r)
    verifyEq(b.union(a), r)
    verifyEq(a.intersects(r), true); verifyEq(r.intersects(a), true)
    verifyEq(b.intersects(r), true); verifyEq(r.intersects(b), true)
    verifyEq(r.intersects(r), true)
  }

//////////////////////////////////////////////////////////////////////////
// Insets
//////////////////////////////////////////////////////////////////////////

  Void testInsets()
  {
    verifyEq(Insets(1, 2, 3, 4), Insets(1, 2, 3, 4))
    verifyEq(Insets(1, 2, 3, 4), Insets(1f, 2f, 3f, 4f))
    verifyEq(Insets(1, 2, 3, 4).top,    1f)
    verifyEq(Insets(1, 2, 3, 4).right,  2f)
    verifyEq(Insets(1, 2, 3, 4).bottom, 3f)
    verifyEq(Insets(1, 2, 3, 4).left,   4f)
    verifyEq(Insets(1, 2, 3, 4).toSize, Size(6,4))
    verifyNotEq(Insets(0, 2, 3, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 0, 3, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 2, 0, 4), Insets(1, 2, 3, 4))
    verifyNotEq(Insets(1, 2, 3, 0), Insets(1, 2, 3, 4))

    verifyEq(Insets(1), Insets(1,1,1,1))
    verifyEq(Insets(1,2), Insets(1,2,1,2))
    verifyEq(Insets(1,2,3), Insets(1,2,3,2))

    verifyEq(Insets(7).toStr, "7")
    verifyEq(Insets(7.5f).toStr, "7.5")
    verifyEq(Insets(1.5f, 2.5f, 3f, 4.2f).toStr, "1.5 2.5 3 4.2")

    verifyEq(Insets.fromStr("3,4,5,6"), Insets(3,4,5,6))
    verifyEq(Insets.fromStr("10"), Insets(10,10,10,10))
    verifyEq(Insets.fromStr("-1 , -2, -3  , -4"), Insets(-1,-2,-3,-4))
    verifyEq(Insets.fromStr("3,4"), Insets(3, 4))
    verifyEq(Insets.fromStr("3,4,5"), Insets(3, 4, 5))
    verifyErr(ParseErr#) { x := Insets.fromStr("3,4,x,6") }
    verifyErr(ParseErr#) { x := Insets.fromStr("", true) }

    verifyEq(Insets(0, 0, 0, 0).isNone, true)
    verifyEq(Insets(1, 0, 0, 0).isNone, false)
    verifyEq(Insets(0, 1, 0, 0).isNone, false)
    verifyEq(Insets(0, 0, 1, 0).isNone, false)
    verifyEq(Insets(0, 0, 0, 1).isNone, false)

    verifySer(Insets(1, 2, 3, 4))
    verifySer(Insets(-1, 2, -3, 4))
  }

  Void verifySer(Obj obj)
  {
    //echo("-- " + Buf.make.writeObj(obj).flip.readAllStr)
    x := Buf.make.writeObj(obj).flip.readObj
    verifyEq(obj, x)
  }


}