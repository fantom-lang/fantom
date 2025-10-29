//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//

**
** Future represents the result of an asynchronous computation.
**
** See [docLang::Actors]`docLang::Actors`
**
@Js
native abstract const class Future
{
  **
  ** Construct a completable future instance in the pending state.
  **
  static Future makeCompletable()

  // NOTE: subclassing APIs are WIP and subject to change

  **
  ** Subclass constructor to wrap future
  **
  @NoDoc protected new make(Future wrap)

  **
  ** Return wrapped future if this is a subclass
  **
  @NoDoc Future? wraps()

  **
  ** Create new instance of subclass that wraps given future
  **
  @NoDoc abstract This wrap(Future wrap)

  **
  ** Block current thread until result is ready.  If timeout occurs
  ** then TimeoutErr is raised.  A null timeout blocks forever.  If
  ** an exception was raised by the asynchronous computation, then it
  ** is raised to the caller of this method.
  **
  virtual Obj? get(Duration? timeout := null)

  **
  ** Return the exception raised by the asynchronous computation or null
  ** if the future completed successfully.  This method can only be used
  ** after completion, otherwise if status pending then raise NotCompleteErr.
  **
  Err? err()

  **
  ** Current state of asynchronous computation
  **
  FutureStatus status()

  **
  ** Cancel this computation if it has not begun processing.
  ** No guarantee is made that the computation will be cancelled.
  **
  Void cancel()

  **
  ** Complete the future successfully with given value.  Raise
  ** an exception if value is not immutable or the future is
  ** already complete (ignore this call if cancelled).
  ** Raise UnsupportedErr if this future is not completable.
  ** Return this. This method is subject to change.
  **
  This complete(Obj? val)

  **
  ** Complete the future with a failure condition using given
  ** exception.  Raise an exception if the future is already
  ** complete (ignore this call if cancelled).  Return this.
  ** Raise UnsupportedErr if this future is not completable.
  ** This method is subject to change.
  **
  This completeErr(Err err)

  **
  ** Register a callback function when this future completes in either
  ** the ok or err/cancel state.  Return a new future that may be chained
  ** for additional async operations that will return the result of the
  ** given callback.
  **
  ** In the Java VM this operation is a blocking operation that has the
  ** same effect as calling `waitFor` and then invoking the given callback
  ** with the result of `get` or `err`.
  **
  ** In JavaScript this operation wraps Promise.then with the same semantics.
  **
  This then(|Obj?->Obj?| onOk, |Err->Obj?|? onErr := null)

  **
  ** Get JavaScript Promise object which backs this Future.
  ** Only available in JavaScript environments.
  **
  Obj promise()

  **
  ** Block until this future transitions to a completed state (ok,
  ** err, or canceled).  If timeout is null then block forever, otherwise
  ** raise a TimeoutErr if timeout elapses.  Return this.
  **
  This waitFor(Duration? timeout := null)

  **
  ** Block on a list of futures until they all transition to a completed
  ** state.  If timeout is null block forever, otherwise raise TimeoutErr
  ** if any one of the futures does not complete before the timeout
  ** elapses.
  **
  static Void waitForAll(Future[] futures, Duration? timeout := null)

}

**************************************************************************
** ActorFuture
**************************************************************************

** Actor implementation for future
internal native final const class ActorFuture  : Future
{
  override This wrap(Future wrap)
}

**************************************************************************
** FutureState
**************************************************************************

** State of a Future's asynchronous computation
@Js
enum class FutureStatus
{
  pending,
  ok,
  err,
  cancelled

  ** Return if pending state
  Bool isPending() { this === pending }

  ** Return if in any completed state: ok, err, or cancelled
  Bool isComplete() { this !== pending }

  ** Return if the ok state
  Bool isOk() { this === ok }

  ** Return if the err state
  Bool isErr() { this === err }

  ** Return if the cancelled state
  Bool isCancelled() { this === cancelled }
}

