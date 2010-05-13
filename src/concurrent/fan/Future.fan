//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//

**
** Future represents the result of an actor's asynchronous
** computation of a message.
**
** See [docLang::Actors]`docLang::Actors`
**
@Js
native final const class Future
{

  **
  ** Private constructor.
  **
  private new make()

  **
  ** Wait for the actor's result.  If timeout occurs then TimeoutErr
  ** is raised.  A null timeout blocks forever.  If an exception was
  ** raised by the Actor, then it is raised to the caller of this method.
  ** If msg is not immutable or serializable, then IOErr is thrown.
  **
  Obj? get(Duration? timeout := null)

  **
  ** Return true if the actor's message has completed processing.
  ** Completion may be due to the actor returning a result,
  ** throwing an exception, or cancellation.
  **
  Bool isDone()

  **
  ** Return if this message has been cancelled.
  **
  Bool isCancelled()

  **
  ** Cancel this message if it has not begun processing.
  ** No guarantee is made that the actor won't process this
  ** message.
  **
  Void cancel()

}