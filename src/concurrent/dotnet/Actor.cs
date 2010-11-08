//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Threading;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// Actor is a worker who processes messages asynchronously.
  /// </summary>
  public class Actor : FanObj, Fanx.Util.ThreadPool.Work
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Actor make(ActorPool pool) { return make(pool, null); }
    public static Actor make(ActorPool pool, Func receive)
    {
      Actor self = new Actor();
      make_(self, pool, receive);
      return self;
    }

    public static void make_(Actor self, ActorPool pool) { make_(self, pool, null); }
    public static void make_(Actor self, ActorPool pool, Func receive)
    {
      // check pool
      if (pool == null)
        throw NullErr.make("pool is null").val;

      // check receive method
      if (receive == null && self.@typeof().qname() == "concurrent::Actor")
        throw ArgErr.make("must supply receive func or subclass Actor").val;
      if (receive != null && !receive.isImmutable())
        throw NotImmutableErr.make("Receive func not immutable: " + receive).val;

      // init
      self.m_pool = pool;
      self.m_receive = receive;
      self.m_queue = new Queue();
    }

    public static Actor makeCoalescing(ActorPool pool, Func k, Func c) { return makeCoalescing(pool, k, c, null); }
    public static Actor makeCoalescing(ActorPool pool, Func k, Func c, Func r)
    {
      Actor self = new Actor();
      makeCoalescing_(self, pool, k, c, r);
      return self;
    }

    public static void makeCoalescing_(Actor self, ActorPool pool, Func k, Func c) { makeCoalescing_(self, pool, k, c, null); }
    public static void makeCoalescing_(Actor self, ActorPool pool, Func k, Func c, Func r)
    {
      if (k != null && !k.isImmutable())
        throw NotImmutableErr.make("Coalescing toKey func not immutable: " + k).val;

      if (c != null && !c.isImmutable())
        throw NotImmutableErr.make("Coalescing coalesce func not immutable: " + c).val;

      make_(self, pool, r);
      self.m_queue = new CoalescingQueue(k, c);
    }

    public Actor()
    {
      this.m_context = new Context(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()
    {
      if (m_type == null) m_type = Type.find("concurrent::Actor");
      return m_type;
    }
    private static Type m_type;

  //////////////////////////////////////////////////////////////////////////
  // Actor
  //////////////////////////////////////////////////////////////////////////

    public ActorPool pool() { return m_pool; }

    public Future send(object msg) { return _send(msg, null, null); }

    public Future sendLater(Duration d, object msg) { return _send(msg, d, null); }

    public Future sendWhenDone(Future f, object msg) { return _send(msg, null, f); }

    protected object receive(object msg)
    {
      if (m_receive != null) return m_receive.call(msg);
      System.Console.WriteLine("WARNING: " + @typeof() + ".receive not overridden");
      return null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static void sleep(Duration duration)
    {
      try
      {
        long ticks = duration.m_ticks;
        System.Threading.Thread.Sleep(new System.TimeSpan(ticks/100));
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
    }

    public static Map locals()
    {
      if (m_locals == null)
        m_locals = new Map(Sys.StrType, Sys.ObjType.toNullable());
      return m_locals;
    }
    [ThreadStatic] static Map m_locals;

  //////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////

    private Future _send(object msg, Duration dur, Future whenDone)
    {
      // ensure immutable or safe copy
      msg = Sys.safe(msg);

      // don't deliver new messages to a stopped pool
      if (m_pool.isStopped()) throw Err.make("ActorPool is stopped").val;

      // get the future instance to manage this message's lifecycle
      Future f = new Future(msg);

      // either enqueue immediately or schedule with pool
      if (dur != null)
        m_pool.schedule(this, dur, f);
      else if (whenDone != null)
        whenDone.sendWhenDone(this, f);
      else
        f = _enqueue(f, true);

      return f;
    }

    internal Future _enqueue(Future f, bool coalesce)
    {
      lock (m_lock)
      {
        // attempt to coalesce
        if (coalesce)
        {
          Future c = m_queue.coalesce(f);
          if (c != null) return c;
        }

        // add to queue
        m_queue.add(f);

        // submit to thread pool if not submitted or current running
        if (!m_submitted)
        {
          m_submitted = true;
          m_pool.submit(this);
        }

        return f;
      }
    }

    public void _work()
    {
      // set locals for this actor
      m_locals = m_context.m_locals;
      Locale.setCur(m_context.m_locale);

      // process up to 100 messages before yielding the thread
      for (int count = 0; count < 100; count++)
      {
        // get next message, or if none pending we are done
        Future future = null;
        lock (m_lock) { future = m_queue.get(); }
        if (future == null) break;

        // dispatch the messge
        _dispatch(future);
      }

      // flush locals back to context
      m_context.m_locale = Locale.cur();

      // done dispatching, either clear the submitted
      // flag or resubmit to the thread pool
      lock (m_lock)
      {
        if (m_queue.size == 0)
        {
          m_submitted = false;
        }
        else
        {
          m_submitted = true;
          m_pool.submit(this);
        }
      }
    }

    internal void _dispatch(Future future)
    {
      try
      {
        if (future.isCancelled()) return;
        if (m_pool.m_killed) { future.cancel(); return; }
        future.set(receive(future.m_msg));
      }
      catch (Err.Val e)
      {
        future.err(e.m_err);
      }
      catch (System.Exception e)
      {
        future.err(Err.make(e));
      }
    }

    public void _kill()
    {
      // get/reset the pending queue
      Queue queue = null;
      lock (m_lock)
      {
        queue = this.m_queue;
        this.m_queue = new Queue();
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

    internal class Queue
    {
      public virtual Future get()
      {
        if (head == null) return null;
        Future f = head;
        head = f.m_next;
        if (head == null) tail = null;
        f.m_next = null;
        size--;
        return f;
      }

      public virtual void add(Future f)
      {
        if (tail == null) { head = tail = f; f.m_next = null; }
        else { tail.m_next = f; tail = f; }
        size++;
      }

      public virtual Future coalesce(Future f)
      {
        return null;
      }

      internal Future head, tail;
      internal int size;
    }

  //////////////////////////////////////////////////////////////////////////
  // CoalescingQueue
  //////////////////////////////////////////////////////////////////////////

    internal class CoalescingQueue : Queue
    {
      public CoalescingQueue(Func toKeyFunc, Func coalesceFunc)
      {
        this.toKeyFunc = toKeyFunc;
        this.coalesceFunc = coalesceFunc;
      }

      public override Future get()
      {
        Future f = base.get();
        if (f != null)
        {
          try
          {
            object key = toKey(f.m_msg);
            if (key != null) pending.Remove(key);
          }
          catch (System.Exception e)
          {
            Err.dumpStack(e);
          }
        }
        return f;
      }

      public override void add(Future f)
      {
        try
        {
          object key = toKey(f.m_msg);
          if (key != null) pending[key] = f;
        }
        catch (System.Exception e)
        {
          Err.dumpStack(e);
        }
        base.add(f);
      }

      public override Future coalesce(Future incoming)
      {
        object key = toKey(incoming.m_msg);
        if (key == null) return null;

        Future orig = (Future)pending[key];
        if (orig == null) return null;

        orig.m_msg = coalesce(orig.m_msg, incoming.m_msg);
        return orig;
      }

      private object toKey(object obj)
      {
        return toKeyFunc == null ? obj : toKeyFunc.call(obj);
      }

      private object coalesce(object orig, object incoming)
      {
        return coalesceFunc == null ? incoming : coalesceFunc.call(orig, incoming);
      }

      Func toKeyFunc, coalesceFunc;
      Hashtable pending = new Hashtable();
    }

  //////////////////////////////////////////////////////////////////////////
  // Context
  //////////////////////////////////////////////////////////////////////////

    internal class Context
    {
      internal Context(Actor actor) { m_actor = actor; }
      internal Actor m_actor;
      internal Map m_locals = new Map(Sys.StrType, Sys.ObjType.toNullable());
      internal Locale m_locale = Locale.cur();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal readonly Context m_context;     // mutable world state of actor
    private ActorPool m_pool;                // pool controller
    private Func m_receive;                  // func to invoke on receive or null
    private object m_lock = new object();    // lock for message queue
    private Queue m_queue;                   // message queue linked list
    private bool m_submitted = false;        // is actor submitted to thread pool

  }
}