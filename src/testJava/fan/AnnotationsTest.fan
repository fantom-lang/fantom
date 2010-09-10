//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 10  Brian Frank  Creation
//

**
** AnnotationsTest
**
class AnnotationsTest : JavaTest
{

  Void test()
  {
    compile(
     """using sys::Test
        using [java] java.lang
        using [java] fanx.interop
        using [java] fanx.test

        @TestAnnoA
        class Test
        {
          new make(Test t) { this.testRef = t }

          Void test()
          {
            testType
            testField
            testMethod
          }

          Void testType()
          {
            // Fantom side
            verifyEq(typeof.facets.size, 1)
            f := typeof.facets[0]
            verifyEq(f.typeof.qname, "[java]fanx.test::TestAnnoA")
            verify(typeof.facet(TestAnnoA#) != null)

            // Java side
            cls := Interop.getClass(this)
            verifyEq(cls.getAnnotations.size, 1)
            verify(cls.getAnnotations[0]  is TestAnnoA)
          }

          Void testField()
          {
            // Fantom side
            verifyEq(#field.facets.size, 1)
            f := #field.facets[0]
            verifyEq(f.typeof.qname, "[java]fanx.test::TestAnnoA")
            verify(#field.facet(TestAnnoA#) != null)

            // Java side
            jf := Interop.getClass(this).getField("field")
            verifyEq(jf.getAnnotations.size, 1)
            verify(jf.getAnnotations[0] is TestAnnoA)
          }

          Void testMethod()
          {
            // Fantom side
            verifyEq(#method.facets.size, 1)
            f := #method.facets[0]
            verifyEq(f.typeof.qname, "[java]fanx.test::TestAnnoA")
            verify(#method.facet(TestAnnoA#) != null)

            // Java side
            jm := Interop.getClass(this).getMethod("method", Class[,])
            verifyEq(jm.getAnnotations.size, 1)
            verify(jm.getAnnotations[0] is TestAnnoA)
          }

          @TestAnnoA
          Str? field

          @TestAnnoA
          Void method() {}

          Void verifyEq(Obj? a, Obj? b) { testRef.verifyEq(a, b) }
          Void verify(Bool c) { testRef.verify(c) }
          Test? testRef
        }""")

    obj := pod.types.first.make([this])
    obj->test
  }

}