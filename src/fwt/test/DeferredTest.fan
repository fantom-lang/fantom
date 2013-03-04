//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Mar 2013  Andy Frank  Creation
//

** DeferredTest
@Js
class DeferredTest : Test
{

//////////////////////////////////////////////////////////////////////////
// TestBasics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    done := [,]
    fail := [,]
    all  := [,]

    // resolve
    def := Deferred
    {
      it.onDone |x| { done.add(x) }
      it.onFail |x| { fail.add(x) }
      it.onAlways |x| { all.add(x) }
    }
    def.resolve("foo")
    verifyEq(done, Obj?["foo"])
    verifyEq(fail, [,])
    verifyEq(all,  Obj?["foo"])
    verifyErr(Err#) |->| { def.resolve("bar") }
    verifyErr(Err#) |->| { def.reject("bar") }

    // reject
    done.clear
    fail.clear
    all.clear
    def = Deferred
    {
      it.onDone |x| { done.add(x) }
      it.onFail |x| { fail.add(x) }
      it.onAlways |x| { all.add(x) }
    }
    def.reject("foo")
    verifyEq(done, [,])
    verifyEq(fail, Obj?["foo"])
    verifyEq(all,  Obj?["foo"])
    verifyErr(Err#) |->| { def.resolve("bar") }
    verifyErr(Err#) |->| { def.reject("bar") }
  }

//////////////////////////////////////////////////////////////////////////
// TestDoneChained
//////////////////////////////////////////////////////////////////////////

  Void testDoneChained()
  {
    list := [,]
    def  := Deferred
    {
      it.onDone |x| { list.add("1$x") }
      it.onDone |x| { list.add("2$x") }

      it.onAlways |x| { list.add("4$x") }
      it.onAlways |x| { list.add("5$x") }
    }

    def.then |x| { list.add("3$x") }

    def.resolve("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a"])

    def.onDone |x| { list.add("6$x") }
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a"])

    def.onAlways |x| { list.add("7$x") }
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }

//////////////////////////////////////////////////////////////////////////
// TestFailChanined
//////////////////////////////////////////////////////////////////////////

  Void testFailChained()
  {
    list := [,]
    def  := Deferred
    {
      it.onFail |x| { list.add("1$x") }
      it.onFail |x| { list.add("2$x") }

      it.onAlways |x| { list.add("4$x") }
      it.onAlways |x| { list.add("5$x") }
    }

    def.then(
      |x| {},
      |x| { list.add("3$x") }
    )

    def.reject("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a"])
  }

//////////////////////////////////////////////////////////////////////////
// TestPromiseDone
//////////////////////////////////////////////////////////////////////////

  Void testPromiseDone()
  {
    list := [,]
    def  := Deferred
    {
      it.onDone   |x| { list.add("1$x") }
      it.onAlways |x| { list.add("5$x") }
    }

    p := def.promise
    p.then     |x| { list.add("2$x") }
    p.onDone   |x| { list.add("3$x") }
    p.onAlways |x| { list.add("6$x") }

    def.onDone   |x| { list.add("4$x") }
    def.onAlways |x| { list.add("7$x") }

    def.resolve("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }

//////////////////////////////////////////////////////////////////////////
// TestPromiseFail
//////////////////////////////////////////////////////////////////////////

  Void testPromiseFail()
  {
    list := [,]
    def  := Deferred
    {
      it.onFail   |x| { list.add("1$x") }
      it.onAlways |x| { list.add("5$x") }
    }

    p := def.promise
    p.then(
      |x| {},
      |x| { list.add("2$x") }
    )
    p.onFail   |x| { list.add("3$x") }
    p.onAlways |x| { list.add("6$x") }

    def.onFail   |x| { list.add("4$x") }
    def.onAlways |x| { list.add("7$x") }

    def.reject("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }
}
