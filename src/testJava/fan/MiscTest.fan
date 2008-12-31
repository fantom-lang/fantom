//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Brian Frank  Creation
//

**
** MiscTest
**
class MiscTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Ctor Wrapper
//////////////////////////////////////////////////////////////////////////

  Void testCtorWrapper()
  {
    // test for bug report 423 31-Dec-08
    compile(
     "using [java] fanx.interop::DoubleArray as FloatArray
      class Matrix
      {
        new make(Num[][] rows := Float[][,]) { this.size = rows.size }
        Int size
      }")

    obj := pod.types.first.make
    verifyEq(obj->size, 0)
  }

}