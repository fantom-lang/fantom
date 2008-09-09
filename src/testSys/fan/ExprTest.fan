//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jun 06  Brian Frank  Creation
//

**
** ExprTest
**
class ExprTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Is
//////////////////////////////////////////////////////////////////////////

  Void testIs()
  {
    Obj x := 4

    verifyEq(x is Int, true)
    verifyEq(x is Num, true)
    verifyEq(x is Obj, true)
    verifyEq(x is Str, false)
    verifyEq(null is Str, false)

    verifyEq(x isnot Int, false)
    verifyEq(x isnot Num, false)
    verifyEq(x isnot Obj, false)
    verifyEq(x isnot Str, true)
    verifyEq(null isnot Str, true)

    verifySame(x as Int, x)
    verifySame(x as Num, x)
    verifySame(x as Obj, x)
    verifySame(x as Str, null)
  }

//////////////////////////////////////////////////////////////////////////
// Ternary
//////////////////////////////////////////////////////////////////////////

  Void testTernary()
  {
    x := 3
    y := 2

    verifyEq(x == y ? 't' : 'f', 'f')
    verifyEq(x != y ? 't' : 'f', 't')
    verifyEq(true  ? (x = 0) : (y = 1), 0); verifyEq(x, 0); verifyEq(y, 2);
    verifyEq(false ? (x = 9) : (y = 8), 8); verifyEq(x, 0); verifyEq(y, 8);

    x = 4; y = 3;
    Str s := x === y ? "x=$x" : "y=$y"
    verifyEq(s, "y=3")
    verifyEq(s = x !== y ? null : "y=$y", null)
    verifyEq(s = x !== y ? "x=$x" : null,  "x=4")
  }

//////////////////////////////////////////////////////////////////////////
// With
//////////////////////////////////////////////////////////////////////////

  Void testWithThisTypes()
  {
    // regression test for bug where This return cast
    // wasn't getting popped off on a with block sub
    y := ExprY { a = ExprZ { add(ExprZ.make) } }
    verifyEq(y.a.kids.size, 1)

    // This return cast popped off on for loop update
    i := 0
    x := ExprZ.make
    for (i=0; i<100; x.add(null)) { i++ }
    verifyEq(i, 100)
  }

}

class ExprX { This add(ExprX k) { kids.add(k); return this } ExprX[] kids := ExprX[,]  }
class ExprY : ExprX { ExprX a }
class ExprZ : ExprX  {}