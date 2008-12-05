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

}