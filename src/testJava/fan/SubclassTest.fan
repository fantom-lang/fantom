//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Brian Frank  Creation
//

**
** SubclassTest
**
class SubclassTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Interface
//////////////////////////////////////////////////////////////////////////

  Void testInterface()
  {
    compile(
     "using [java] java.lang
      class Run : Runnable
      {
        override Void run() { count++ }
        Void test1() { Runnable r := this; r.run }
        static Void test2(Runnable r) { r.run() }
        Int count
      }")

    obj := pod.types.first.make
    verifyEq(obj->count, 0)
    obj->run
    verifyEq(obj->count, 1)
    obj->test1
    verifyEq(obj->count, 2)
    obj->test2(obj)
    verifyEq(obj->count, 3)
  }

//////////////////////////////////////////////////////////////////////////
// Class
//////////////////////////////////////////////////////////////////////////

  Void testClass()
  {
    // this tests a bunch of stuff including normal extending a class
    // and an interface, using all those of methods, protected methods,
    // and overrides
    compile(
     "using [java] java.util
      class Foo : Observable, Observer
      {
        Bool test1() { return countObservers == 0}
        Bool test2() { addObserver(this); return countObservers == 1 }
        Bool test3() { setChanged(); notifyObservers(5ms); return arg == 5ms }
        override Void update(Observable? o, Obj? arg) { this.arg = arg }
        Obj? arg
      }")

    obj := pod.types.first.make
    verify(obj->test1)
    verify(obj->test2)
    verify(obj->test3)
  }

//////////////////////////////////////////////////////////////////////////
// Overloads
//////////////////////////////////////////////////////////////////////////

  Void testOverloads()
  {
    compile(
     "using [java] fanx.test
      class Foo : InteropTest
      {
        Int test1() { return numi }
        Int test2() { return numi() }
        Int test3() { numi(33); return numi() }
      }")

    obj := pod.types.first.make
    verifyEq(obj->test1, 'i')
    verifyEq(obj->test2, 1000)
    verifyEq(obj->test3, 33)
  }

//////////////////////////////////////////////////////////////////////////
// Java Overrides
//////////////////////////////////////////////////////////////////////////

  Void testJavaOverrides()
  {
    compile(
     "using [java] fanx.test::InteropTest\$JavaOverrides as JavaOverrides
      class Foo : JavaOverrides
      {
        override Int add(Int a, Int b) { return a + b }
        override Obj[]? arraySelf() { return Obj[this] }
        override Obj? arrayGet(Obj[]? a, Int i) { return a[i] }

        Int test1() { return add(4, 5) }
        Obj test2() { return arraySelf[0] }
        Obj test3(Obj[] var, Int i) { return arrayGet(var, i) }
      }")

    obj := pod.types.first.make
    verifyEq(obj->test1, 9)
    verifySame(obj->test2, obj)
    verifyEq(obj->test3(["a", "b", "c"], 2), "c")
  }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  Void testCtors()
  {
    compile(
     "using [java] java.util
      class Foo : Date
      {
        new make() : super() {}
        new makeTicks(Int millis) : super(millis) {}
        new makeWith(Int year, Int mon, Int day) : super(year-1900, mon, day) {}

        DateTime now := DateTime.now

        Bool test1() { return make.verify(now.year, now.month, now.day) }
        Bool test2() { return makeTicks(now.toJava).verify(now.year, now.month, now.day) }
        Bool test3() { return makeWith(2000, 5, 7).verify(2000, Month.jun, 7) }
        Bool test4() { return foo == 77 }
        Bool test5() { return sfoo == 88 }

        Bool verify(Int year, Month mon, Int day)
        {
          //Obj.echo(\"year=\$getYear ?= \$year mon=\$getMonth ?= \$mon day=\$getDate ?= \$day\")
          return getYear+1900 == year && getMonth == mon.ordinal && getDate == day
        }

        Int foo := 77
        const static Int sfoo := 88
      }")

    obj := pod.types.first.make
    verify(obj->test1)
    verify(obj->test2)
    verify(obj->test3)
    verify(obj->test4)
    verify(obj->test5)
  }

}