//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System.Collections;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// Controller for a group of actors which manages their execution.
  /// </summary>
  public class ActorPool : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static ActorPool make() { return make(null); }
    public static ActorPool make(Func itBlock)
    {
      ActorPool self = new ActorPool();
      make_(self, itBlock);
      return self;
    }

    public static void make_(ActorPool self) { make_(self, null); }
    public static void make_(ActorPool self, Func itBlock)
    {
      if (itBlock != null)
      {
        itBlock.enterCtor(self);
        itBlock.call(self);
        itBlock.exitCtor();
      }
      if (self.m_maxThreads < 1) throw ArgErr.make("ActorPool.maxThreads must be >= 1, not " + self.m_maxThreads).val;

      self.m_threadPool = new ThreadPool((int)self.m_maxThreads);
      self.m_scheduler = new Scheduler();
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()
    {
      if (m_type == null) m_type = Type.find("concurrent::ActorPool");
      return m_type;
    }
    private static Type m_type;

  //////////////////////////////////////////////////////////////////////////
  // ActorPool
  //////////////////////////////////////////////////////////////////////////

    public bool isStopped()
    {
      return m_threadPool.isStopped();
    }

    public bool isDone()
    {
      return m_threadPool.isDone();
    }

    public ActorPool stop()
    {
      m_scheduler.stop();
      m_threadPool.stop();
      return this;
    }

    public ActorPool kill()
    {
      m_killed = true;
      m_scheduler.stop();
      m_threadPool.kill();
      return this;
    }

    public ActorPool join() { return join(null); }
    public ActorPool join(Duration timeout)
    {
      if (!isStopped()) throw Err.make("ActorPool is not stopped").val;
      long ms = timeout == null ? System.Int32.MaxValue : timeout.millis();
      try
      {
        if (m_threadPool.join(ms)) return this;
      }
      catch (System.Threading.ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
      throw TimeoutErr.make("ActorPool.join timed out").val;
    }

    public override object trap(string name, List args)
    {
      if (name == "dump") { m_threadPool.dump(args); return null; }
      return base.trap(name, args);
    }

    internal void submit(Actor actor)
    {
      m_threadPool.submit(actor);
    }

    internal void schedule(Actor a, Duration d, Future f)
    {
      m_scheduler.schedule(d.ticks(), new ScheduledWork(a, f));
    }

  //////////////////////////////////////////////////////////////////////////
  // ScheduledWork
  //////////////////////////////////////////////////////////////////////////

    internal class ScheduledWork : Scheduler.Work
    {
      public ScheduledWork(Actor a, Future f) { actor = a; future = f; }
      public string toString() { return "ScheduledWork msg=" + future.m_msg; }
      public void work() { if (!future.isCancelled()) actor._enqueue(future, false); }
      public void cancel() { future.cancel(); }
      internal readonly Actor actor;
      internal readonly Future future;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private ThreadPool m_threadPool;
    private Scheduler m_scheduler;
    internal volatile bool m_killed;
    public long m_maxThreads = 100;

  }
}