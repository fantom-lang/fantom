//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Nov 08  Brian Frank  Creation
//

using testCompiler

**
** CheckErrorsTest
**
class CheckErrorsTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Calls
//////////////////////////////////////////////////////////////////////////

  Void testCalls()
  {
    // ResolveExpr step
    verifyErrors(
     "using [java] java.lang
      class Foo
      {
        static Void m00() { System.getProperty() }
        static Void m01() { System.getProperty(\"foo\", \"bar\", 4) }
        static Void m02() { System.getProperty(\"foo\", 4) }
        static System? m03() { m03.getProperty(\"foo\"); return null }
      }
      ",
       [
          4, 30, "Invalid args getProperty()",
          5, 30, "Invalid args getProperty(sys::Str, sys::Str, sys::Int)",
          6, 30, "Invalid args getProperty(sys::Str, sys::Int)",
       ])

    // CheckErrors step
    verifyErrors(
     "using [java] java.lang
      class Foo
      {
        static System? m00() { m00.getProperty(\"foo\"); return null }
      }
      ",
       [
          4, 30, "Cannot call static method 'getProperty' on instance",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Multi-dimensional Arrays
//////////////////////////////////////////////////////////////////////////

  Void testMultiDimArrays()
  {
    verifyErrors(
     "using [java] fanx.test
      class Foo
      {
        static Void m00() { v := InteropTest().dateMulti2() }
        static Void m01() { v := InteropTest().dateMulti3() }
        static Void m02() { v := InteropTest().strMulti2() }
        static Void m03() { v := InteropTest().strMulti3() }
        static Void m04() { v := InteropTest().intMulti2() }
        static Void m05() { v := InteropTest().intMulti3() }
        static Void m06() { v := InteropTest().doubleMulti2() }
        static Void m07() { v := InteropTest().doubleMulti3() }
      }
      ",
       [
          4, 42, "Method 'dateMulti2' uses unsupported type '[java]java.util::[[Date'",
          5, 42, "Method 'dateMulti3' uses unsupported type '[java]java.util::[[[Date'",
          6, 42, "Method 'strMulti2' uses unsupported type '[java]java.lang::[[String'",
          7, 42, "Method 'strMulti3' uses unsupported type '[java]java.lang::[[[String'",
          8, 42, "Method 'intMulti2' uses unsupported type '[java]::[[int'",
          9, 42, "Method 'intMulti3' uses unsupported type '[java]::[[[int'",
         10, 42, "Method 'doubleMulti2' uses unsupported type '[java]::[[double'",
         11, 42, "Method 'doubleMulti3' uses unsupported type '[java]::[[[double'",
       ])
   }

}