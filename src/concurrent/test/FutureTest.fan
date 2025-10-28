//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 25  Brian Frank  Creation
//

**
** FutureTest
**
class FutureTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup/Teardown
//////////////////////////////////////////////////////////////////////////

  ActorPool pool := ActorPool()

  override Void teardown() { pool.kill }

//////////////////////////////////////////////////////////////////////////
// Completable
//////////////////////////////////////////////////////////////////////////

  Void testCompletable()
  {
    f := Future.makeCompletable
    verifyEq(f.status, FutureStatus.pending)
    verifySame(f.typeof, ActorFuture#)
    verifySame(f.typeof.base, Future#)

    // can only complete with immutable value
    verifyErr(NotImmutableErr#) { f.complete(this) }
    verifySame(f.status, FutureStatus.pending)
    verifyErr(NotCompleteErr#) { f.err }

    // verify complete
    f.complete("done!")
    verifySame(f.status, FutureStatus.ok)
    verifyEq(f.get, "done!")
    verifyEq(f.err, null)

    // can only complete once
    verifyErr(Err#) { f.complete("no!") }
    verifyErr(Err#) { f.completeErr(Err()) }
    verifySame(f.status, FutureStatus.ok)
    verifyEq(f.get, "done!")
    verifyEq(f.err, null)

    // verify completeErr
    f = Future.makeCompletable
    verifyEq(f.status, FutureStatus.pending)
    err := CastErr()
    f.completeErr(err)
    verifySame(f.status, FutureStatus.err)
    verifyErr(CastErr#) { f.get }
    verifyErr(Err#) { f.complete("no!") }
    verifyErr(Err#) { f.completeErr(Err()) }
    verifySame(f.status, FutureStatus.err)
    verifyErr(CastErr#) { f.get }
    verifyEq(f.err.typeof, CastErr#)

    // verify cancel;
    f = Future.makeCompletable
    f.cancel
    verifySame(f.status, FutureStatus.cancelled)
    verifyErr(CancelledErr#) { f.get }
    f.complete("no!")
    f.completeErr(IOErr())
    verifySame(f.status, FutureStatus.cancelled)
    verifyErr(CancelledErr#) { f.get }
    verifyEq(f.err.typeof, CancelledErr#)

    // promise
    if (Env.cur.runtime != "js")
    {
      verifyErr(UnsupportedErr#) { f.promise }
    }
    else
    {
      verifyNotNull(f.promise)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Then
//////////////////////////////////////////////////////////////////////////

  Void testThen()
  {
    f := Future.makeCompletable
    verifySame(f.status, FutureStatus.pending)

    // complete ok
    res := null
    err := null
    completeLaterOk(f, "okay")
    f2 := f.then |r->Obj?| { res = r; return "done!" }
    verifyEq(f.status, FutureStatus.ok)
    verifyEq(res, "okay")
    verifyEq(err, err)
    verifyEq(f2.status, FutureStatus.ok)
    verifyEq(f2.get, "done!")
    verifyEq(f2.err, null)

    // verify immediately calls then again
    res = err = null
    f3 := f.then |r->Obj?| { res = r; return "done 3!"  }
    verifyEq(res, "okay")
    verifyEq(err, err)
    verifyEq(f3.get, "done 3!")

    // complete errror
    f = Future.makeCompletable
    verifySame(f.status, FutureStatus.pending)
    res = err = null
    completeLaterErr(f, IOErr("foo"))
    f4 := f.then(|r->Obj?| { res = r; return "nope" }, |e->Obj?| { err = e; return "done 4!" })
    verifyEq(f.status, FutureStatus.err)
    verifyEq(res, null)
    verifyEq(err?.toStr, "sys::IOErr: foo")
    verifyEq(f4.status, FutureStatus.ok)
    verifyEq(f4.get, "done 4!")
    verifyEq(f4.err, null)

    // verify immediate calls then again
    res = err = null
    f5 := f.then(|r->Obj?| { res = r; return "nope" }, |e->Obj?| { err = e; throw Err("bad") })
    verifyEq(f.status, FutureStatus.err)
    verifyEq(res, null)
    verifyEq(err?.toStr, "sys::IOErr: foo")
    verifyEq(f5.status, FutureStatus.err)
    verifyErr(Err#) { f5.get }
    verifyEq(f5.err?.toStr, "sys::Err: bad")

    // complete cancel
    f = Future.makeCompletable
    verifySame(f.status, FutureStatus.pending)
    res = err = null
    completeLaterCancel(f)
    f6 := f.then(|r->Obj?| { res = r; return "nope" }, |e->Obj?| { err = e; return "done 6!" })
    verifyEq(f.status, FutureStatus.cancelled)
    verifyEq(res, null)
    verifyEq(err?.toStr, "sys::CancelledErr: Future cancelled")
    verifyEq(f6.status, FutureStatus.ok)
    verifyEq(f6.get, "done 6!")
    verifyEq(f6.err, null)

    // chain
    f = Future.makeCompletable
    verifySame(f.status, FutureStatus.pending)
    acc := [,]
    completeLaterOk(f, "a")
    f7 := f.then |x->Str| { x.toStr + "b" }
           .then |x->Str| { x.toStr + "c"  }
           .then |x->Str| { x.toStr + "d"  }
    verifyEq(f7.get, "abcd")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void completeLaterOk(Future f, Obj? val)
  {
    callLater { f.complete(val) }
  }

  Void completeLaterErr(Future f, Err err)
  {
    callLater { f.completeErr(err) }
  }

  Void completeLaterCancel(Future f)
  {
    callLater { f.cancel }
  }

  Void callLater(|Obj| f)
  {
    a := Actor(pool) |msg| { f(msg); return null }
    fut := a.sendLater(10ms, "x")
  }
}

