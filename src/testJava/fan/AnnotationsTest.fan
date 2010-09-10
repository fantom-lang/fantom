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
     Str<|using sys::Test
          using [java] java.lang
          using [java] fanx.interop
          using [java] fanx.test

          @TestAnnoA
          @TestAnnoB { value = "it works!" }
          @TestAnnoC
          {
            b = true
            s = "!"
          }
          class Test
          {
            @TestAnnoA
            @TestAnnoB { value = "it works!" }
            Str? field

            @TestAnnoA
            @TestAnnoB { value = "it works!" }
            Void method() {}

            new make(Test t) { this.testRef = t }

            Void test()
            {
              testType
              testField
              testMethod
            }

            Void testType()
            {
              cls := Interop.getClass(this)
              verifyEq(cls.getAnnotations.size, 3)

              verifyA(typeof.facet(TestAnnoA#), cls.getAnnotation(TestAnnoA#->toClass))
              verifyB(typeof.facet(TestAnnoB#), cls.getAnnotation(TestAnnoB#->toClass))
              verifyC(typeof.facet(TestAnnoC#), cls.getAnnotation(TestAnnoC#->toClass))
            }

            Void testField()
            {
              jf := Interop.getClass(this).getField("field")
              verifyEq(jf.getAnnotations.size, 2)

              verifyA(#field.facet(TestAnnoA#), jf.getAnnotation(TestAnnoA#->toClass))
              verifyB(#field.facet(TestAnnoB#), jf.getAnnotation(TestAnnoB#->toClass))
            }

            Void testMethod()
            {
              jm := Interop.getClass(this).getMethod("method", Class[,])
              verifyEq(jm.getAnnotations.size, 2)

              verifyA(#method.facet(TestAnnoA#), jm.getAnnotation(TestAnnoA#->toClass))
              verifyB(#method.facet(TestAnnoB#), jm.getAnnotation(TestAnnoB#->toClass))
            }

            Void verifyA(Obj fan, TestAnnoA java)
            {
              //echo("---> verifyA $fan  $java")
              verifyEq(fan.typeof.qname, "[java]fanx.test::TestAnnoA")
              verify(java is TestAnnoA)
            }

            Void verifyB(Obj fan, TestAnnoB java)
            {
              //echo("---> verifyB $fan  $java")
              verifyEq(fan.typeof.qname, "[java]fanx.test::TestAnnoB")
              verify(java is TestAnnoB)
              verifyEq(java.value, "it works!")
            }

            Void verifyC(Obj fan, TestAnnoC java)
            {
              //echo("---> verifyC $fan  $java")
              verifyEq(fan.typeof.qname, "[java]fanx.test::TestAnnoC")
              verify(java is TestAnnoC)
              verifyEq(java.b, true)
              verifyEq(java.s, "!")
            }

            Void verifyEq(Obj? a, Obj? b) { testRef.verifyEq(a, b) }
            Void verify(Bool c) { testRef.verify(c) }
            Test? testRef
          }|>)

    obj := pod.types.first.make([this])
    obj->test
  }

}