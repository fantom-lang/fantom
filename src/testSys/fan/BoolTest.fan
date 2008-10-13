//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 06  Brian Frank  Creation
//

**
** BoolTest
**
class BoolTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    Obj x := true
    Bool? t := true
    Bool? f := false
    verify(x.isImmutable)
    verify(x.type === Bool#)
    verify(true.isImmutable)
    verify(true == true)
    verify(false == false)
    verify(true != false)
    verify(false != x)
    verify(x != "wow")
    verify(t != null)
    verify(null != f)
    verify(t.equals(t))
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  Void testCompare()
  {
    verify(null  <  false)
    verify(null  <  true)
    verify(false <  true)
    verifyFalse(null  >  false)
    verifyFalse(null  >  true)
    verifyFalse(false >  false)

    verify(null  <= false)
    verify(null  <= true)
    verify(false <= true)
    verify(false <= false)
    verify(true  <= true)
    verifyFalse(null  >= false)
    verifyFalse(null  >= true)
    verifyFalse(false >= true)

    verify(true  >  false)
    verify(false >  null)
    verify(true  >  null)
    verifyFalse(true  <  false)
    verifyFalse(false <  null)
    verifyFalse(true  <  null)

    verify(false >= false)
    verify(true  >= true)
    verify(true  >= false)
    verify(false >= null)
    verify(true  >= null)
    verifyFalse(true  <= false)
    verifyFalse(false <= null)
    verifyFalse(true  <= null)

    verifyEq(true <=> false, 1)
    verifyEq(true <=> true, 0)
    verifyEq(null <=> false, -1)
    verifyEq(true.compare(false), 1)
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  Void testOperators()
  {
    t := true
    f := false
    Str? s := null

    // not
    verify(!f)
    verifyFalse(!t)

    // logical and
    verifyEq(f && f, false)
    verifyEq(f && t, false)
    verifyEq(t && f, false)
    verifyEq(t && t, true)

    // logical and - short circuit
    verifyEq(s != null && s.size == 0, false)
    verifyErr(NullErr#) |,| { verifyEq(s == null && s.size == 0, false) }

    // logical or
    verifyEq(f || f, false)
    verifyEq(f || t, true)
    verifyEq(t || f, true)
    verifyEq(t || t, true)

    // logical or - short circuit
    verifyEq(s == null || s.size == 0, true)
    verifyErr(NullErr#) |,| { verifyEq(s != null || s.size == 0, false) }

    // bitwise and
    verifyEq(f & f, false)
    verifyEq(f & t, false)
    verifyEq(t & f, false)
    verifyEq(t & t, true)

    // bitwise and - no short circuit
    verifyErr(NullErr#) |,| { verifyEq((s != null) & (s.size == 0), false) }
    verifyErr(NullErr#) |,| { verifyEq((s == null) & (s.size == 0), false) }

    // bitwise or
    verifyEq(f | f, false)
    verifyEq(f | t, true)
    verifyEq(t | f, true)
    verifyEq(t | t, true)

    // bitwise or - no short circuit
    verifyErr(NullErr#) |,| { verifyEq((s == null) | (s.size == 0), true) }
    verifyErr(NullErr#) |,| { verifyEq((s != null) | (s.size == 0), false) }

    // bitwise xor
    verifyEq(f ^ f, false)
    verifyEq(f ^ t, true)
    verifyEq(t ^ f, true)
    verifyEq(t ^ t, false)

    // bitwise xor - no short circuit
    verifyErr(NullErr#) |,| { verifyEq((s == null) ^ (s.size == 0), true) }
    verifyErr(NullErr#) |,| { verifyEq((s != null) ^ (s.size == 0), false) }

    // bitwise and assignment
    Bool x := false
    x = false; x &= false; verifyEq(x, false)
    x = false; x &= true;  verifyEq(x, false)
    x = true;  x &= false; verifyEq(x, false)
    x = true;  x &= true;  verifyEq(x, true)

    // bitwise or assignment
    x = false; x |= false; verifyEq(x, false)
    x = false; x |= true;  verifyEq(x, true)
    x = true;  x |= false; verifyEq(x, true)
    x = true;  x |= true;  verifyEq(x, true)

    // bitwise xor assignment
    x = false; x ^= false; verifyEq(x, false)
    x = false; x ^= true;  verifyEq(x, true)
    x = true;  x ^= false; verifyEq(x, true)
    x = true;  x ^= true;  verifyEq(x, false)
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  Void testParse()
  {
    verifyEq(true.toStr, "true")
    verifyEq(false.toStr, "false")
    verifyEq(Bool.fromStr("true"), true)
    verifyEq(Bool.fromStr("false"), false)
    verifyEq(Bool.fromStr("F", false), null)
    verifyErr(ParseErr#) |,| { Bool.fromStr("True") }
    verifyErr(ParseErr#) |,| { Bool.fromStr("") }
  }

}