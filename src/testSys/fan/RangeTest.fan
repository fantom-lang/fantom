//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Mar 06  Brian Frank  Creation
//

**
** RangeTest
**
class RangeTest : Test
{

  Void testType()
  {
    r := 0..2
    verifyEq(r.type, Range#)
  }

  Void testEquals()
  {
    Obj? x := 0..2
    verifySame(x.type, Range#)
    verify(x == Range.makeInclusive(0, 2))
    verify(x != Range.makeExclusive(0, 2))
    verify(0...2 != Range.makeInclusive(0, 2))
    verify(0...2 == Range.makeExclusive(0, 2))
    verify(x!= "wow")
    verify(0..1  == 0..1)
    verify(0..-1 == 0..-1)
    verify(0..-1 != 0..1)
    verify(0..-1 != -1..0)
    verify(x != null)
    verify(null != x)
  }

  Void testToStr()
  {
    verifyEq((0..2).toStr, "0..2")
    verifyEq((0...2).toStr, "0...2")
  }

  Void testStartEnd()
  {
    verifyEq((0..2).start, 0)
    verifyEq((0..2).end, 2)
    verifyEq((0..2).inclusive, true)
    verifyEq((0..2).exclusive, false)

    verifyEq((0...2).start, 0)
    verifyEq((0...2).end, 2)
    verifyEq((0...2).inclusive, false)
    verifyEq((0...2).exclusive, true)

    verifyEq((-2..-1).start, -2)
    verifyEq((-2..-1).end, -1)
    verifyEq((-2..-1).inclusive, true)
    verifyEq((-2..-1).exclusive, false)
  }

  Void testContains()
  {
    verifyEq((-2..2).contains(-3), false)
    verifyEq((-2..2).contains(-2), true)
    verifyEq((-2..2).contains(0), true)
    verifyEq((-2..2).contains(2), true)
    verifyEq((-2...2).contains(2), false)
    verifyEq((-2..2).contains(3), false)
    verifyEq((-2...2).contains(3), false)
  }

  Void testEach()
  {
    list := Int[,]

    list.clear;
    (2..4).each |Int i| { list.add(i) }
    verifyEq(list, [2, 3, 4])

    list.clear;
    ('a'...'d').each |Int i| { list.add(i) }
    verifyEq(list, ['a', 'b', 'c'])
  }

  Void testRange()
  {
    verifyEq((2..4).toList, [2,3,4])
    verifyEq((2...4).toList, [2,3])
    verifyEq((-2..2).toList, [-2,-1,0,1,2])
    verifyEq((10..8).toList, [10,9,8])
    verifyEq((10...8).toList, [10,9])
    verifyEq((-4..-8).toList, [-4,-5,-6,-7,-8])
  }

}