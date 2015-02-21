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
    if (self.maxThreads < 1) throw ArgErr.make("ActorPool.maxThreads must be >= 1, not " + self.maxThreads);

    self.threadPool = new ThreadPool(self.name, (int)self.maxThreads);
    self.scheduler = new Scheduler(self.name);
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
    if (!isStopped()) throw Err.make("ActorPool is not stopped");
    long ms = timeout == null ? Long.MAX_VALUE : timeout.millis();
    try
    {
      if (threadPool.join(ms)) return this;
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e);
    }
    throw TimeoutErr.make("ActorPool.join timed out");
  }

  public Object trap(String name, List args)
  {
    if (name.equals("dump")) return dump(args);
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
// Debug
//////////////////////////////////////////////////////////////////////////

  public final Object dump(List args)
  {
    fan.sys.OutStream out = fan.sys.Env.cur().out();
    if (args != null && args.size() > 0)
      out = (fan.sys.OutStream)args.get(0);
    try
    {
      out.printLine("ActorPool");
      out.printLine("  name:       " + name);
      out.printLine("  maxThreads: " + maxThreads);
      threadPool.dump(out);
    }
    catch (Exception e) { out.printLine("  " + e + "\n"); }
    return out;
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
  public String name = "ActorPool";
  public long maxThreads = 100;
  public long maxMsgsBeforeYield = 100;
}