//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Future is used to manage the entire lifecycle of each
 * message send to an Actor.  An actor's queue is a linked
 * list of messages.
 */
public final class Future
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  Future(Object msg)
  {
    this.msg   = msg;
    this.state = PENDING;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.FutureType; }

//////////////////////////////////////////////////////////////////////////
// Future
//////////////////////////////////////////////////////////////////////////

  public final boolean isDone()
  {
    return (state & DONE) != 0;
  }

  public final boolean isCancelled()
  {
    return state == DONE_CANCEL;
  }

  public final Object get() { return get(null); }
  public final synchronized Object get(Duration timeout)
  {
    Object r = null;
    try
    {
      // wait until we enter a done state
      while ((state & DONE) == 0)
      {
        if (timeout == null)
          wait();
        else
          wait(timeout.millis());
      }

      // if canceled throw CancelErr
      if (state == DONE_CANCEL)
        throw CancelledErr.make("message canceled").val;

      // if error was raised, raise it to caller
      if (state == DONE_ERR)
        throw ((Err)result).rebase();

      // assign result to local variable to return
      r = result;
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }

    // ensure immutable or safe copy
    return Namespace.safe(r);
  }

  public final synchronized void cancel()
  {
    if ((state & DONE) == 0) state = DONE_CANCEL;
    notifyAll();
  }

  final synchronized void set(Object r)
  {
    state = DONE_OK;
    result = r;
    notifyAll();
  }

  final synchronized void err(Err e)
  {
    state = DONE_ERR;
    result = e;
    notifyAll();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final int PENDING     = 0x00;
  static final int PROCESSING  = 0x01;
  static final int DONE        = 0x02;
  static final int DONE_CANCEL = 0x12;
  static final int DONE_OK     = 0x22;
  static final int DONE_ERR    = 0x42;

  final Object msg;            // message send to Actor
  Future next;                 // linked list in Actor
  private volatile int state;  // processing state of message
  private Object result;       // result or exception of processing

}