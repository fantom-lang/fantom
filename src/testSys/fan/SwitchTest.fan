//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 May 06  Brian Frank  Creation
//

**
** SwitchTest
**
class SwitchTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Int TableSwitch
//////////////////////////////////////////////////////////////////////////

  Void testIntTableSwitch()
  {
//    verifyEq(intTableNone(-1), "default")
//    verifyEq(intTableNone(3), "default")

    verifyEq(intTableOne(-1), "default")
    verifyEq(intTableOne(0), "zero")
    verifyEq(intTableOne(1), "default")
    verifyEq(intTableOne(9999999), "default")

    verifyEq(intTableTwo(-99999), "default")
    verifyEq(intTableTwo(0), "zero")
    verifyEq(intTableTwo(1), "one")
    verifyEq(intTableTwo(2), "default")

    verifyEq(intTableThree(-99999), "default")
    verifyEq(intTableThree(0),  "zero")
    verifyEq(intTableThree(1),  "one")
    verifyEq(intTableThree(2),  "two")
    verifyEq(intTableThree(3),  "default")
    verifyEq(intTableThree(-2), "default")

    verifyEq(intTableHighShift(999), "default")
    verifyEq(intTableHighShift(1000), "1000")
    verifyEq(intTableHighShift(1002), "1002")
    verifyEq(intTableHighShift(2),    "default")
  }

/* TODO - this will become a if/else switch or optimize it out completely
  Str intTableNone(Int i)
  {
    switch (i)
    {
      default: return "default"
    }
  }
*/

  Str intTableOne(Int i)
  {
    switch (i)
    {
      case 0:  return "zero"
      default: return "default"
    }
  }

  Str intTableTwo(Int i)
  {
    switch (i)
    {
      case 0:  return "zero"
      case 1:  return "one"
      default: return "default"
    }
  }

  Str intTableThree(Int i)
  {
    switch (i)
    {
      case 0:  return "zero"
      case 1:  return "one"
      case 2:  return "two"
      default: return "default"
    }
  }

  Str intTableThreeUnsorted(Int i)
  {
    switch (i)
    {
      case 1:  return "one"
      case 2:  return "two"
      case 0:  return "zero"
      default: return "default"
    }
  }

  Str intTableHighShift(Int i)
  {
    switch (i)
    {
      case 1000: return "1000"
      case 1001: return "1001"
      case 1002: return "1002"
    }
    return "default";
  }

/* TODO - need constant folding optimization and this should solve itself
  Str intTableWithNeg(Int i)
  {
    switch (i)
    {
      case -2: return "-2"
      case -1: return "-2"
      case 0: return  "0"
      case +1: return "+1"
      case +2: return "+2"
    }
    return "default";
  }
*/

//////////////////////////////////////////////////////////////////////////
// Int TableSwitch
//////////////////////////////////////////////////////////////////////////

  Void testEnumTableSwitch()
  {
    verifyEq(enumTableSwitchA(SwitchEnum.zero),  "default");
    verifyEq(enumTableSwitchA(SwitchEnum.one),   "one");
    verifyEq(enumTableSwitchA(SwitchEnum.two),   "default");
    verifyEq(enumTableSwitchA(SwitchEnum.three), "three");
    verifyEq(enumTableSwitchA(SwitchEnum.four),  "default");

    verifyEq(enumTableSwitchB(SwitchEnum.zero),  "default");
    verifyEq(enumTableSwitchB(SwitchEnum.one),   "one");
    verifyEq(enumTableSwitchB(SwitchEnum.two),   "default");
    verifyEq(enumTableSwitchB(SwitchEnum.three), "three");
    verifyEq(enumTableSwitchB(SwitchEnum.four),  "default");
  }

  Str? enumTableSwitchA(SwitchEnum e)
  {
    Str? s := null
    switch (e)
    {
      case SwitchEnum.one:   s = "one"
      case SwitchEnum.three: s = "three"
      default:               s = "default"
    }
    return s
  }

  Str enumTableSwitchB(SwitchEnum e)
  {
    Str s := "default"
    switch (e)
    {
      case SwitchEnum.one:   s = "one"
      case SwitchEnum.three: s = "three"
    }
    return s
  }

//////////////////////////////////////////////////////////////////////////
// Fall Thru
//////////////////////////////////////////////////////////////////////////

  Void testFallThru()
  {
    verifyEq(fallThru(0), "even");
    verifyEq(fallThru(1), "odd");
    verifyEq(fallThru(2), "even");
    verifyEq(fallThru(3), "odd");
    verifyEq(fallThru(4), "default");
  }

  Str fallThru(Int i)
  {
    switch (i)
    {
      case 0:
      case 2:  return "even"
      case 1:
      case 3:  return "odd"
      default: return "default"
    }
  }

//////////////////////////////////////////////////////////////////////////
// Implicit Break
//////////////////////////////////////////////////////////////////////////

  Void testImplicitBreak()
  {
    verifyEq(implicitBreak(0), "zero");
    verifyEq(implicitBreak(1), "one");
    verifyEq(implicitBreak(2), "two");
    verifyEq(implicitBreak(3), "default");
  }

  Str implicitBreak(Int i)
  {
    x := "default"
    switch (i)
    {
      case 1:  x = "one"
      case 2:  x = "two"
      case 0:  x = "zero"
    }
    return x
  }

}

//////////////////////////////////////////////////////////////////////////
// SwitchEnum
//////////////////////////////////////////////////////////////////////////

enum SwitchEnum
{
  zero,
  one,
  two,
  three,
  four
}


// TODO:
//   - no error checking
//   - string/type/wide int range switch
//   - verify cases are constant