//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//

**
** Actor is a worker who processes messages asynchronously.
**
const class Actor
{
  **
  ** Create an actor whose execution is controlled by the given ActorGroup.
  ** If receive is non-null, then it is used to process messages sent to
  ** this actor.  If receive is specified then it must be an immutable
  ** function (it cannot capture state from the calling thread), otherwise
  ** NotImmutableErr is thrown.  If receive is null, then you must subclass
  ** Actor and override the `receive` method.
  **
  new make(ActorGroup group, |Context,Obj? -> Obj?|? receive := null)

  **
  ** The group used to control execution of this actor.
  **
  ActorGroup group()

  **
  ** Asynchronously send a message to this actor for processing.
  ** If msg is not immutable or serializable, then IOErr is thrown.
  ** Throw Err if this actor's group has been stopped.  Return
  ** a future which may be used to obtain the result once it the
  ** actor has processed the message.
  **
  Future send(Obj? msg)

  **
  ** Schedule a message for delivery after the specified period of
  ** duration has elapsed.  Once the period has elapsed the message is
  ** appended to the end of this actor's queue.  Accuracy of scheduling
  ** is dependent on thread coordination and pending messages in the queue.
  ** Scheduled messages are not guaranteed to be processed if the
  ** actor's grouped is stopped.
  **
  Future schedule(Duration d, Obj? msg)

  **
  ** The receive behavior for this actor is handled by overriding
  ** this method or by passing a function to the constructor.  Return
  ** the result made available by the Future.  If an exception
  ** is raised by this method, then it is raised by 'Future.get'.
  **
  protected virtual Obj? receive(Context cx, Obj? msg)

}