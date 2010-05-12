//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.concurrent;

import fan.sys.*;
import java.util.HashMap;

/**
 * Actor is a worker who processes messages asynchronously.
 */
public class Actor
  extends FanObj
  implements ThreadPool.Work
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Actor make(ActorPool pool) { return make(pool, null); }
  public static Actor make(ActorPool pool, Func receive)
  {
    Actor self = new Actor();
    make$(self, pool, receive);
    return self;
  }

  public static void make$(Actor self, ActorPool pool) { make$(self, pool, null); }
  public static void make$(Actor self, ActorPool pool, Func receive)
  {
    // check pool
    if (pool == null)
      throw NullErr.make("pool is null").val;

    // check receive method
    if (receive == null && self.typeof().qname().equals("concurrent::Actor"))
      throw ArgErr.make("must supply receive func or subclass Actor").val;
    if (receive != null) receive = (Func)receive.toImmutable();

    // init
    self.pool = pool;
    self.receive = receive;
    self.queue = new Queue();
  }

  public static Actor makeCoalescing(ActorPool pool, Func k, Func c) { return makeCoalescing(pool, k, c, null); }
  public static Actor makeCoalescing(ActorPool pool, Func k, Func c, Func r)
  {
    Actor self = new Actor();
    makeCoalescing$(self, pool, k, c, r);
    return self;
  }

  public static void makeCoalescing$(Actor self, ActorPool pool, Func k, Func c) { makeCoalescing$(self, pool, k, c, null); }
  public static void makeCoalescing$(Actor self, ActorPool pool, Func k, Func c, Func r)
  {
    if (k != null) k = (Func)k.toImmutable();
    if (c != null) c = (Func)c.toImmutable();

    make$(self, pool, r);
    self.queue = new CoalescingQueue(k, c);
  }

  public Actor()
  {
    this.context  = new Context(this);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof()
  {
    if (type == null) type = Type.find("concurrent::Actor");
    return type;
  }
  private static Type type;

//////////////////////////////////////////////////////////////////////////
// Actor
//////////////////////////////////////////////////////////////////////////

  public final ActorPool pool() { return pool; }

  public final Future send(Object msg) { return _send(msg, null, null); }

  public final Future sendLater(Duration d, Object msg) { return _send(msg, d, null); }

  public final Future sendWhenDone(Future f, Object msg) { return _send(msg, null, f); }

  protected Object receive(Object msg)
  {
    if (receive != null) return receive.call(msg);
    System.out.println("WARNING: " + typeof() + ".receive not overridden");
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public static void sleep(Duration duration)
  {
    try
    {
      long ticks = duration.ticks;
      java.lang.Thread.sleep(ticks/1000000L, (int)(ticks%1000000L));
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
  }

  public static Map locals() { return (Map)locals.get(); }
  private static final ThreadLocal locals = new ThreadLocal()
  {
    protected Object initialValue()
    {
      return new Map(Sys.StrType, Sys.ObjType.toNullable());
    }
  };

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  private Future _send(Object msg, Duration dur, Future whenDone)
  {
    // ensure immutable or safe copy
    msg = Sys.safe(msg);

    // don't deliver new messages to a stopped pool
    if (pool.isStopped()) throw Err.make("ActorPool is stopped").val;

    // get the future instance to manage this message's lifecycle
    Future f = new Future(msg);

    // either enqueue immediately or schedule with pool
    if (dur != null)
      pool.schedule(this, dur, f);
    else if (whenDone != null)
      whenDone.sendWhenDone(this, f);
    else
      f = _enqueue(f, true);

    return f;
  }

  final Future _enqueue(Future f, boolean coalesce)
  {
    synchronized (lock)
    {
      // attempt to coalesce
      if (coalesce)
      {
        Future c = queue.coalesce(f);
        if (c != null) return c;
      }

      // add to queue
      queue.add(f);

      // submit to thread pool if not submitted or current running
      if (!submitted)
      {
        submitted = true;
        pool.submit(this);
      }

      return f;
    }
  }

  public final void _work()
  {
    // set locals for this actor
    locals.set(context.locals);
    Locale.setCur(context.locale);

    // process up to 100 messages before yielding the thread
    for (int count = 0; count < 100; count++)
    {
      // get next message, or if none pending we are done
      Future future = null;
      synchronized (lock) { future = queue.get(); }
      if (future == null) break;

      // dispatch the messge
      _dispatch(future);
    }

    // flush locals back to context
    context.locale = Locale.cur();

    // done dispatching, either clear the submitted
    // flag or resubmit to the thread pool
    synchronized (lock)
    {
      if (queue.size == 0)
      {
        submitted = false;
      }
      else
      {
        submitted = true;
        pool.submit(this);
      }
    }

  }

  final void _dispatch(Future future)
  {
    try
    {
      if (future.isCancelled()) return;
      if (pool.killed) { future.cancel(); return; }
      future.set(receive(future.msg));
    }
    catch (Err.Val e)
    {
      future.err(e.err());
    }
    catch (Throwable e)
    {
      future.err(Err.make(e));
    }
  }

  public void _kill()
  {
    // get/reset the pending queue
    Queue queue = null;
    synchronized (lock)
    {
      queue = this.queue;
      this.queue = new Queue();
    }

    // cancel all pending messages
    while (true)
    {
      Future future = queue.get();
      if (future == null) break;
      future.cancel();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Queue
//////////////////////////////////////////////////////////////////////////

  static class Queue
  {
    public Future get()
    {
      if (head == null) return null;
      Future f = head;
      head = f.next;
      if (head == null) tail = null;
      f.next = null;
      size--;
      return f;
    }

    public void add(Future f)
    {
      if (tail == null) { head = tail = f; f.next = null; }
      else { tail.next = f; tail = f; }
      size++;
    }

    public Future coalesce(Future f)
    {
      return null;
    }

    Future head, tail;
    int size;
  }

//////////////////////////////////////////////////////////////////////////
// CoalescingQueue
//////////////////////////////////////////////////////////////////////////

  static class CoalescingQueue extends Queue
  {
    CoalescingQueue(Func toKeyFunc, Func coalesceFunc)
    {
      this.toKeyFunc = toKeyFunc;
      this.coalesceFunc = coalesceFunc;
    }

    public Future get()
    {
      Future f = super.get();
      if (f != null)
      {
        try
        {
          Object key = toKey(f.msg);
          if (key != null) pending.remove(key);
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
      return f;
    }

    public void add(Future f)
    {
      try
      {
        Object key = toKey(f.msg);
        if (key != null) pending.put(key, f);
      }
      catch (Throwable e)
      {
        e.printStackTrace();
      }
      super.add(f);
    }

    public Future coalesce(Future incoming)
    {
      Object key = toKey(incoming.msg);
      if (key == null) return null;

      Future orig = (Future)pending.get(key);
      if (orig == null) return null;

      orig.msg = coalesce(orig.msg, incoming.msg);
      return orig;
    }

    private Object toKey(Object obj)
    {
      return toKeyFunc == null ? obj : toKeyFunc.call(obj);
    }

    private Object coalesce(Object orig, Object incoming)
    {
      return coalesceFunc == null ? incoming : coalesceFunc.call(orig, incoming);
    }

    Func toKeyFunc, coalesceFunc;
    HashMap pending = new HashMap();
  }

//////////////////////////////////////////////////////////////////////////
// Context
//////////////////////////////////////////////////////////////////////////

  static final class Context
  {
    Context(Actor actor) { this.actor = actor; }
    final Actor actor;
    final Map locals = new Map(Sys.StrType, Sys.ObjType.toNullable());
    Locale locale = Locale.cur();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Context context;                 // mutable world state of actor
  private ActorPool pool;                // pooled controller
  private Func receive;                  // func to invoke on receive or null
  private Object lock = new Object();    // lock for message queue
  private Queue queue;                   // message queue linked list
  private boolean submitted = false;     // is actor submitted to thread pool

}