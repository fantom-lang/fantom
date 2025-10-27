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
  }

}

