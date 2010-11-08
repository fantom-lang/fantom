//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System.Collections;
using System.Runtime.CompilerServices;
using System.Threading;

namespace Fan.Sys
{
  /// <summary>
  /// Future is used to manage the entire lifecycle of each
  /// message send to an Actor.  An actor's queue is a linked
  /// list of messages.
  /// </summary>
  public sealed class Future : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    internal Future(object msg)
    {
      this.m_msg   = msg;
      this.m_state = PENDING;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()
    {
      if (m_type == null) m_type = Type.find("concurrent::Future");
      return m_type;
    }
    private static Type m_type;

  //////////////////////////////////////////////////////////////////////////
  // Future
  //////////////////////////////////////////////////////////////////////////

    public bool isDone()
    {
      return (m_state & DONE) != 0;
    }

    public bool isCancelled()
    {
      return m_state == DONE_CANCEL;
    }

    public object get() { return get(null); }
    public object get(Duration timeout)
    {
      object r = null;
      try
      {
        lock (this)
        {
          // wait until we enter a done state, the only notifies
          // on this object should be from cancel, set, or err
          if (timeout == null)
          {
            // wait forever until done
            while ((m_state & DONE) == 0) Monitor.Wait(this);
          }
          else
          {
            // if not done, then wait with timeout and then
            // if still not done throw a timeout exception
            if ((m_state & DONE) == 0)
            {
              Monitor.Wait(this, (int)timeout.millis());
              if ((m_state & DONE) == 0) throw TimeoutErr.make("Future.get timed out").val;
            }
          }

          // if canceled throw CancelErr
          if (m_state == DONE_CANCEL)
            throw CancelledErr.make("message canceled").val;

          // if error was raised, raise it to caller
          if (m_state == DONE_ERR)
            throw ((Err)m_result).rebase();

          // assign result to local variable for return
          r = m_result;
        }
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }

      // ensure immutable or safe copy
      return Sys.safe(r);
    }

    public void cancel()
    {
      ArrayList wd;
      lock (this)
      {
        if ((m_state & DONE) == 0) m_state = DONE_CANCEL;
        m_msg = m_result = null;  // allow gc
        Monitor.PulseAll(this);
        wd = whenDone; whenDone = null;
      }
      sendWhenDone(wd);
    }

    internal void set(object r)
    {
      r = Sys.safe(r);
      ArrayList wd;
      lock (this)
      {
        m_state = DONE_OK;
        m_result = r;
        Monitor.PulseAll(this);
        wd = whenDone; whenDone = null;
      }
      sendWhenDone(wd);
    }

    internal void err(Err e)
    {
      ArrayList wd;
      lock (this)
      {
        m_state = DONE_ERR;
        m_result = e;
        Monitor.PulseAll(this);
        wd = whenDone; whenDone = null;
      }
      sendWhenDone(wd);
    }

  //////////////////////////////////////////////////////////////////////////
  // When Done
  //////////////////////////////////////////////////////////////////////////

    internal void sendWhenDone(Actor a, Future f)
    {
      // if already done, then set immediate flag
      // otherwise add to our when done list
      bool immediate = false;
      lock (this)
      {
        if (isDone()) immediate = true;
        else
        {
          if (whenDone == null) whenDone = new ArrayList();
          whenDone.Add(new WhenDone(a, f));
        }
      }

      // if immediate we are already done so enqueue immediately
      if (immediate)
      {
        try { a._enqueue(f, false); }
        catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    internal static void sendWhenDone(ArrayList list)
    {
      if (list == null) return;
      for (int i=0; i<list.Count; ++i)
      {
        WhenDone wd = (WhenDone)list[i];
        try { wd.actor._enqueue(wd.future, false); }
        catch (System.Exception e) { Err.dumpStack(e); }
      }
    }

    internal class WhenDone
    {
      public WhenDone(Actor a, Future f) { actor = a; future = f; }
      public Actor actor;
      public Future future;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    const int PENDING     = 0x00;
    const int DONE        = 0x0f;
    const int DONE_CANCEL = 0x1f;
    const int DONE_OK     = 0x2f;
    const int DONE_ERR    = 0x4f;

    internal object m_msg;         // message send to Actor
    internal Future m_next;        // linked list in Actor
    private volatile int m_state;  // processing state of message
    private object m_result;       // result or exception of processing
    private ArrayList whenDone;    // list of messages to deliver when done

  }
}