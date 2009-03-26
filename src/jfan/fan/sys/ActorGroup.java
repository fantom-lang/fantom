//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

import java.util.concurrent.*;

/**
 * Controller for a group of actors which manages their execution.
 */
public class ActorGroup
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ActorGroup make()
  {
    ActorGroup self = new ActorGroup();
    make$(self);
    return self;
  }

  public static void make$(ActorGroup self)
  {
  }

  public ActorGroup()
  {
    // TODO: not an effective flow control policy
    executor = new ThreadPoolExecutor(1, 100, 60, TimeUnit.SECONDS, new SynchronousQueue());
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ActorGroupType; }

//////////////////////////////////////////////////////////////////////////
// ActorGroup
//////////////////////////////////////////////////////////////////////////

  public final boolean isStopped()
  {
    return executor.isShutdown();
  }

  public final boolean isDone()
  {
    return executor.isTerminated();
  }

  public final ActorGroup stop()
  {
    executor.shutdown();
    return this;
  }

  public final ActorGroup kill()
  {
    java.util.List pending = executor.shutdownNow();
    for (int i=0; i<pending.size(); ++i)
      ((Actor.RunWrapper)pending.get(i)).actor._kill();
    return this;
  }

  public final ActorGroup join() { return join(null); }
  public final ActorGroup join(Duration timeout)
  {
    long ns = timeout == null ? Long.MAX_VALUE : timeout.ticks;
    try
    {
      executor.awaitTermination(ns, TimeUnit.NANOSECONDS);
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
    return this;
  }

  final void submit(Actor actor)
  {
    executor.execute(actor.runnable);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final ExecutorService executor;
}