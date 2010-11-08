//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.concurrent;

import fan.sys.*;

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

  public static ActorPool make() { return make(null); }
  public static ActorPool make(Func func)
  {
    ActorPool self = new ActorPool();
    make$(self, func);
    return self;
  }

  public static void make$(ActorPool self) { make$(self, null); }
  public static void make$(ActorPool self, Func itBlock)
  {
    if (itBlock != null)
    {
      itBlock.enterCtor(self);
      itBlock.call(self);
      itBlock.exitCtor();
    }
    if (self.maxThreads < 1) throw ArgErr.make("ActorPool.maxThreads must be >= 1, not " + self.maxThreads).val;

    self.threadPool = new ThreadPool((int)self.maxThreads);
    self.scheduler = new Scheduler();
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof()
  {
    if (type == null) type = Type.find("concurrent::ActorPool");
    return type;
  }
  private static Type type;

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

  private ThreadPool threadPool;
  private Scheduler scheduler;
  volatile boolean killed;
  public long maxThreads = 100;

}