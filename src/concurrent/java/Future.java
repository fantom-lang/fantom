//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//   24 Apr 20  Brian Frank  Make Future abstract
//
package fan.concurrent;

import fan.sys.*;
import java.util.concurrent.TimeUnit;
import java.util.ArrayList;

/**
 * Future is used to manage the entire lifecycle of each
 * message send to an Actor.  An actor's queue is a linked
 * list of messages.
 */
public abstract class Future
  extends FanObj
  implements java.util.concurrent.Future
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Future makeCompletable() { return new ActorFuture(null); }

  public static void make$(Future self, Future wraps)
  {
    self.wraps = wraps;
  }

  public Future() {}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return typeof$(); }

  public static Type typeof$()
  {
    if (type == null) type = Type.find("concurrent::Future");
    return type;
  }
  private static Type type;

//////////////////////////////////////////////////////////////////////////
// Future
//////////////////////////////////////////////////////////////////////////

  public final boolean isDone() { return status().isComplete(); }

  public final boolean isCancelled() { return status().isCancelled(); }

  public FutureStatus status()
  {
    return wrapped().status();
  }

  public Object get() { return get(null); }
  public final Object get(long t, TimeUnit u) { return get(Duration.make(u.toNanos(t))); }
  public Object get(Duration timeout)
  {
    return wrapped().get(timeout);
  }

  public Err err()
  {
    return wrapped().err();
  }

  public final Future waitFor() { return waitFor(null); }
  public Future waitFor(Duration timeout)
  {
    wrapped().waitFor(timeout);
    return this;
  }

  public final Future then(Func onOk) { return then(onOk, null); }
  public Future then(Func onOk, Func onErr)
  {
    return wrap(wrapped().then(onOk, onErr));
  }

  public static final void waitForAll(List<Future> list) { waitForAll(list, null); }
  public static final void waitForAll(List<Future> list, Duration timeout)
  {
    if (timeout == null)
    {
      for (int i=0; i<list.sz(); ++i)
      {
        Future f = (Future)list.get(i);
        f.waitFor(null);
      }
    }
    else
    {
      long deadline = Duration.nowMillis() + timeout.millis();
      for (int i=0; i<list.sz(); ++i)
      {
        Future f = (Future)list.get(i);
        long left = deadline - Duration.nowMillis();
        f.waitFor(Duration.makeMillis(left));
      }
    }
  }

  // java Future version
  public final boolean cancel(boolean mayInterrupt)
  {
    cancel();
    return true;
  }

  public void cancel()
  {
    wrapped().cancel();
  }

  public Future complete(Object r)
  {
    wrapped().complete(r);
    return this;
  }

  public Future completeErr(Err e)
  {
    wrapped().completeErr(e);
    return this;
  }

  public Object promise()
  {
    throw UnsupportedErr.make("Not available in Java VM");
  }

  public abstract Future wrap(Future wrap);

  public Future wraps() { return wraps; }

  Future wrapped()
  {
    if (wraps == null) throw UnsupportedErr.make("Future missing wraps");
    return wraps;
  }

  private Future wraps;
}

