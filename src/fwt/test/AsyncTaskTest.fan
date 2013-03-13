//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Mar 2013  Andy Frank  Creation
//

** AsyncTaskTest
@Js
class AsyncTaskTest : Test
{

//////////////////////////////////////////////////////////////////////////
// testBasics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    done := [,]
    err  := [,]
    all  := [,]

    // done
    task := AsyncTask
    {
      it.onDone |x| { done.add(x) }
      it.onErr  |x| { err.add(x) }
      it.onDoneOrErr |x| { all.add(x) }
    }
    task.markDone("foo")
    verifyEq(done, Obj?["foo"])
    verifyEq(err,  Obj?[,])
    verifyEq(all,  Obj?["foo"])
    verifyErr(Err#) |->| { task.markDone("bar") }
    verifyErr(Err#) |->| { task.markErr("bar") }

    // err
    done.clear
    err.clear
    all.clear
    task = AsyncTask
    {
      it.onDone |x| { done.add(x) }
      it.onErr  |x| { err.add(x) }
      it.onDoneOrErr |x| { all.add(x) }
    }
    task.markErr("foo")
    verifyEq(done, Obj?[,])
    verifyEq(err,  Obj?["foo"])
    verifyEq(all,  Obj?["foo"])
    verifyErr(Err#) |->| { task.markDone("bar") }
    verifyErr(Err#) |->| { task.markErr("bar") }
  }

//////////////////////////////////////////////////////////////////////////
// testDoneChained
//////////////////////////////////////////////////////////////////////////

  Void testDoneChained()
  {
    list := [,]
    task := AsyncTask
    {
      it.onDone |x| { list.add("1$x") }
      it.onDone |x| { list.add("2$x") }

      it.onDoneOrErr |x| { list.add("4$x") }
      it.onDoneOrErr |x| { list.add("5$x") }
    }

    task.then |x| { list.add("3$x") }

    task.markDone("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a"])

    task.onDone |x| { list.add("6$x") }
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a"])

    task.onDoneOrErr |x| { list.add("7$x") }
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }

//////////////////////////////////////////////////////////////////////////
// testErrChanined
//////////////////////////////////////////////////////////////////////////

  Void testFailChained()
  {
    list := [,]
    task  := AsyncTask
    {
      it.onErr |x| { list.add("1$x") }
      it.onErr |x| { list.add("2$x") }

      it.onDoneOrErr |x| { list.add("4$x") }
      it.onDoneOrErr |x| { list.add("5$x") }
    }

    task.then(
      |x| {},
      |x| { list.add("3$x") }
    )

    task.markErr("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a"])
  }

//////////////////////////////////////////////////////////////////////////
// testRoDone
//////////////////////////////////////////////////////////////////////////

  Void testRoDone()
  {
    list := [,]
    task := AsyncTask
    {
      it.onDone |x| { list.add("1$x") }
      it.onDoneOrErr |x| { list.add("5$x") }
    }

    ro := task.ro
    ro.then   |x| { list.add("2$x") }
    ro.onDone |x| { list.add("3$x") }
    ro.onDoneOrErr |x| { list.add("6$x") }

    task.onDone   |x| { list.add("4$x") }
    task.onDoneOrErr |x| { list.add("7$x") }

    verifyErr(Err#) |->| { ro.markDone("x") }
    verifyErr(Err#) |->| { ro.markErr("y") }

    task.markDone("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }

//////////////////////////////////////////////////////////////////////////
// testRoErr
//////////////////////////////////////////////////////////////////////////

  Void testRoErr()
  {
    list := [,]
    task := AsyncTask
    {
      it.onErr |x| { list.add("1$x") }
      it.onDoneOrErr |x| { list.add("5$x") }
    }

    ro := task.ro
    ro.then(
      |x| {},
      |x| { list.add("2$x") }
    )
    ro.onErr |x| { list.add("3$x") }
    ro.onDoneOrErr |x| { list.add("6$x") }

    task.onErr   |x| { list.add("4$x") }
    task.onDoneOrErr |x| { list.add("7$x") }

    verifyErr(Err#) |->| { ro.markDone("x") }
    verifyErr(Err#) |->| { ro.markErr("y") }

    task.markErr("a")
    verifyEq(list, Obj?["1a", "2a", "3a", "4a", "5a", "6a", "7a"])
  }
}
