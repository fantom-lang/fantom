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
          using [java] java.lang::Thread$State as ThreadState

          @TestAnnoA
          @TestAnnoB { value = "it works!" }
          @TestAnnoC
          {
            bool = true
            str  = "!"
            i    = 123
            b    = -50
            s    = 1000
            l    = 456
            f    = 2f
            d    = -66f
            e    = ThreadState.BLOCKED
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
              verifyEq(typeof.facets.size, 0)
              verifyErr(UnknownFacetErr#) { this.typeof.facet(TestAnnoA#) }
              verifyErr(UnknownFacetErr#) { this.typeof.facet(TestAnnoB#) }
              verifyErr(UnknownFacetErr#) { this.typeof.facet(TestAnnoC#) }

              cls := Interop.getClass(this)
              verifyEq(cls.getAnnotations.size, 3)

              verifyA(cls.getAnnotation(TestAnnoA#->toClass))
              verifyB(cls.getAnnotation(TestAnnoB#->toClass))
              verifyC(cls.getAnnotation(TestAnnoC#->toClass))
            }

            Void testField()
            {
              verifyEq(#field.facets.size, 0)
              verifyErr(UnknownFacetErr#) { #field.facet(TestAnnoA#) }
              verifyErr(UnknownFacetErr#) { #field.facet(TestAnnoB#) }

              jf := Interop.getClass(this).getField("field")
              verifyEq(jf.getAnnotations.size, 2)

              verifyA(jf.getAnnotation(TestAnnoA#->toClass))
              verifyB(jf.getAnnotation(TestAnnoB#->toClass))
            }

            Void testMethod()
            {
              verifyEq(#method.facets.size, 0)
              verifyErr(UnknownFacetErr#) { #method.facet(TestAnnoA#) }
              verifyErr(UnknownFacetErr#) { #method.facet(TestAnnoB#) }

              jm := Interop.getClass(this).getMethod("method", Class[,])
              verifyEq(jm.getAnnotations.size, 2)

              verifyA(jm.getAnnotation(TestAnnoA#->toClass))
              verifyB(jm.getAnnotation(TestAnnoB#->toClass))
            }

            Void verifyA(TestAnnoA java)
            {
              //echo("---> verifyA $fan  $java")
              verify(java is TestAnnoA)
            }

            Void verifyB(TestAnnoB java)
            {
              //echo("---> verifyB $fan  $java")
              verify(java is TestAnnoB)
              verifyEq(java.value, "it works!")
            }

            Void verifyC(TestAnnoC java)
            {
              //echo("---> verifyC $fan  $java")
              verify(java is TestAnnoC)
              verifyEq(java.bool, true)
              verifyEq(java.str,  "!")
              verifyEq(java.i,    123)
              verifyEq(java.b,    -50)
              verifyEq(java.s,    1000)
              verifyEq(java.l,    456)
              verifyEq(java.f,    2f)
              verifyEq(java.d,    -66f)
              verifyEq(java.e,    ThreadState.BLOCKED)
            }

            Void verifyEq(Obj? a, Obj? b) { testRef.verifyEq(a, b) }
            Void verifyErr(Type t, |Test| f) { testRef.verifyErr( t, f) }
            Void verify(Bool c) { testRef.verify(c) }
            Test? testRef
          }|>)

    obj := pod.types.first.make([this])
    obj->test
  }

}