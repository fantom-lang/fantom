//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

import fanx.util.ThreadPool;
import fanx.util.Scheduler;

/**
 * Controller for a group of actors which manages their execution
 * using pooled thread resources.
 */
public class ActorPool
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ActorPool make()
  {
    ActorPool self = new ActorPool();
    make$(self);
    return self;
  }

  public static void make$(ActorPool self)
  {
  }

  public ActorPool()
  {
    threadPool = new ThreadPool(100);
    scheduler = new Scheduler();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ActorPoolType; }

//////////////////////////////////////////////////////////////////////////
// ActorPool
//////////////////////////////////////////////////////////////////////////

  public final boolean isStopped()
  {
    return threadPool.isStopped();
  }

  public final boolean isDone()
  {
    return threadPool.isDone();
  }

  public final ActorPool stop()
  {
    scheduler.stop();
    threadPool.stop();
    return this;
  }

  public final ActorPool kill()
  {
    killed = true;
    scheduler.stop();
    threadPool.kill();
    return this;
  }

  public final ActorPool join() { return join(null); }
  public final ActorPool join(Duration timeout)
  {
    if (!isStopped()) throw Err.make("ActorPool is not stopped").val;
    long ms = timeout == null ? Long.MAX_VALUE : timeout.millis();
    try
    {
      if (threadPool.join(ms)) return this;
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
    throw TimeoutErr.make("ActorPool.join timed out").val;
  }

  public Object trap(String name, List args)
  {
    if (name.equals("dump")) { threadPool.dump(args); return null; }
    return super.trap(name, args);
  }

  final void submit(Actor actor)
  {
    threadPool.submit(actor);
  }

  final void schedule(Actor a, Duration d, Future f)
  {
    scheduler.schedule(d.ticks(), new ScheduledWork(a, f));
  }

//////////////////////////////////////////////////////////////////////////
// ScheduledWork
//////////////////////////////////////////////////////////////////////////

  static class ScheduledWork implements Scheduler.Work
  {
    ScheduledWork(Actor a, Future f) { actor = a; future = f; }
    public String toString() { return "ScheduledWork msg=" + future.msg; }
    public void work() { if (!future.isCancelled()) actor._enqueue(future, false); }
    public void cancel() { future.cancel(); }
    final Actor actor;
    final Future future;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final ThreadPool threadPool;
  private final Scheduler scheduler;
  volatile boolean killed;

}