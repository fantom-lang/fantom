//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 May 06  Brian Frank  Creation
//

**
** StrBufTest
**
class StrBufTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Size
//////////////////////////////////////////////////////////////////////////

  Void testSize()
  {
    s := StrBuf.make
    verifyEq(s.size, 0)
    verifyEq(s.isEmpty, true)
    verifyEq(s.toStr, "")

    s.add("foo")
    verifyEq(s.size, 3)
    verifyEq(s.isEmpty, false)
    verifyEq(s.toStr, "foo")
  }

//////////////////////////////////////////////////////////////////////////
// Get/Set
//////////////////////////////////////////////////////////////////////////

  Void testGetSet()
  {
    s := StrBuf.make(8).add("abcd")
    verifyEq(s.size, 4)
    verifyEq(s[0], 'a')
    verifyEq(s[1], 'b')
    verifyEq(s[2], 'c')
    verifyEq(s[3], 'd')
    verifyEq(s[-1], 'd')
    verifyEq(s[-2], 'c')
    verifyEq(s[-3], 'b')
    verifyEq(s[-4], 'a')

    s[0]  = 'A'; verifyEq(s.toStr, "Abcd")
    s[-1] = 'D'; verifyEq(s.toStr, "AbcD")
    s[-3] = 'B'; verifyEq(s.toStr, "ABcD")
    s[2]  = 'C'; verifyEq(s.toStr, "ABCD")

    verifyErr(IndexErr#) |,| { x := s[4] }
    verifyErr(IndexErr#) |,| { x := s[-5] }
    verifyErr(IndexErr#) |,| { s[4] = 'x' }
    verifyErr(IndexErr#) |,| { s[-5] = 'x' }
    verifyEq(s.toStr, "ABCD")
  }

//////////////////////////////////////////////////////////////////////////
// Add
//////////////////////////////////////////////////////////////////////////

  Void testAdd()
  {
    s := StrBuf.make
    s.add("abc")
    s.addChar('d')
    s.add(null)
    s.addChar('\n')
    verifyEq(s.toStr, "abcdnull\n")
  }

//////////////////////////////////////////////////////////////////////////
// Join
//////////////////////////////////////////////////////////////////////////

  Void testJoin()
  {
    s := StrBuf()
    s.join(null);   verifyEq(s.toStr, "null")
    s.join(null);   verifyEq(s.toStr, "null null")
    s.join(3, ";"); verifyEq(s.toStr, "null null;3")
    s.clear
    s.join(3, "; "); verifyEq(s.toStr, "3")
    s.join(5, "; "); verifyEq(s.toStr, "3; 5")
  }

//////////////////////////////////////////////////////////////////////////
// Insert
//////////////////////////////////////////////////////////////////////////

  Void testInsert()
  {
    s := StrBuf.make
    s.insert(0, "xyz")
    verifyEq(s.toStr, "xyz")
    s.insert(0, 4)
    verifyEq(s.toStr, "4xyz")
    s.insert(1, null)
    verifyEq(s.toStr, "4nullxyz")
    s.insert(-1, "A")
    verifyEq(s.toStr, "4nullxyAz")
    s.insert(-2, true)
    verifyEq(s.toStr, "4nullxytrueAz")

    s.clear.add("abc")
    verifyErr(IndexErr#) |,| { s.insert(4, "x") }
    verifyErr(IndexErr#) |,| { s.insert(-4, "x") }
  }

//////////////////////////////////////////////////////////////////////////
// Remove
//////////////////////////////////////////////////////////////////////////

  Void testRemove()
  {
    s := StrBuf.make.add("abcdef")
    s.remove(0)
    verifyEq(s.toStr, "bcdef")
    s.remove(2)
    verifyEq(s.toStr, "bcef")
    s.remove(-1)
    verifyEq(s.toStr, "bce")
    s.remove(-2)
    verifyEq(s.toStr, "be")
    s.remove(1)
    verifyEq(s.toStr, "b")
    s.remove(0)
    verifyEq(s.toStr, "")

    s.add("abcdef")
    verifyErr(IndexErr#) |,| { s.remove(-7) }
    verifyErr(IndexErr#) |,| { s.remove(6) }
  }

//////////////////////////////////////////////////////////////////////////
// RemoveRange
//////////////////////////////////////////////////////////////////////////

  Void testRemoveRange()
  {
    s := StrBuf.make.add("abcdefghijklmnop")
    verifyEq(s.removeRange(0..<2).toStr,  "cdefghijklmnop")
    verifyEq(s.removeRange(1..3).toStr,   "cghijklmnop")
    verifyEq(s.removeRange(-3..-2).toStr, "cghijklmp")
    verifyEq(s.removeRange(-1..-1).toStr, "cghijklm")
    verifyEq(s.removeRange(4..<-2).toStr, "cghilm")
    verifyEq(s.removeRange(1..1).toStr,   "chilm")
    verifyEq(s.removeRange(-3..-1).toStr, "ch")
    verifyEq(s.removeRange(0..1).toStr,   "")

    verifyErr(IndexErr#) { StrBuf().add("").removeRange(0..1) }
    verifyErr(IndexErr#) { StrBuf().add("abc").removeRange(0..3) }
    verifyErr(IndexErr#) { StrBuf().add("abc").removeRange(0..<4) }
    verifyErr(IndexErr#) { StrBuf().add("abc").removeRange(-4..-1) }
  }

//////////////////////////////////////////////////////////////////////////
// Clear
//////////////////////////////////////////////////////////////////////////

  Void testClear()
  {
    s := StrBuf.make
    s.add("foo")
    verifyEq(s.size, 3)
    verifyEq(s.isEmpty, false)
    verifyEq(s.toStr, "foo")
    s.clear()
    verifyEq(s.size, 0)
    verifyEq(s.isEmpty, true)
    verifyEq(s.toStr, "")
  }

//////////////////////////////////////////////////////////////////////////
// TODO
//////////////////////////////////////////////////////////////////////////

  // TODO - pretty much everything

}