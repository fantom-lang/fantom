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
native final const class Future
{

  **
  ** Construct a future in the pending state.
  ** TODO: prototype feature
  **
  new make()

  **
  ** Block current thread until result is ready.  If timeout occurs
  ** then TimeoutErr is raised.  A null timeout blocks forever.  If
  ** an exception was raised by the asynchronous computation, then it
  ** is raised to the caller of this method.
  **
  Obj? get(Duration? timeout := null)

  **
  ** Current state of asynchronous computation
  **
  FutureState state()

  **
  ** Return true if the asynchronous computation has completed
  ** processing.  Completion may be due to the computation returning
  ** a result, throwing an exception, or cancellation.
  **
  @Deprecated { msg = "Use Future.state" }
  Bool isDone()

  **
  ** Return if this message has been cancelled.
  **
  @Deprecated { msg = "Use Future.state" }
  Bool isCancelled()

  **
  ** Cancel this computation if it has not begun processing.
  ** No guarantee is made that the computation will be cancelled.
  **
  Void cancel()

  **
  ** Complete the future successfully with given value.  Raise
  ** an exception if value is not immutable or the future is not
  ** in the pending state.
  **
  ** TODO: prototype feature
  **
  Void complete(Obj? val)

  **
  ** Complete the future with a failure condition using given
  ** exception.  Raise an exceptoin if value the future is not
  ** in the pending state.
  **
  ** TODO: prototype feature
  **
  Void completeErr(Err err)

}

**************************************************************************
** FutureState
**************************************************************************

** State of a Future's asynchronous computation
@Js
enum class FutureState
{
  pending,
  ok,
  err,
  cancelled

  ** Return if pending state
  Bool isPending() { this === pending }

  ** Return if in any completed state: ok, err, or cancelled
  Bool isComplete() { this !== pending }
}