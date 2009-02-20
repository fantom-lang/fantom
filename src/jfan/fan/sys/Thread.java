//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;

/**
 * Thread models a thread of execution within a process.
 */
public class Thread
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Thread make() { return make(null, null); }
  public static Thread make(String name) { return make(name, null); }
  public static Thread make(String name, Func run)
  {
    Thread t = new Thread();
    make$(t, name, run);
    return t;
  }

  public static void make$(Thread t) { make$(t, null, null); }
  public static void make$(Thread t, String name) { make$(t, name, null); }
  public static void make$(Thread t, String name, Func run)
  {
    // if service, get inheritance types before acquiring lock
    List serviceTypes = null;
    if (t.isService())
      serviceTypes = t.type().inheritance();

    synchronized (topLock)
    {
      // check run method
      if (run != null && !run.isImmutable())
        throw NotImmutableErr.make("Run method not const: " + run).val;

      // auto generate name if null
      if (name == null)
        name = t.type().pod().name() + "." + t.type().name() + "." + (autoNameCount++);

      // verify name is valid
      Uri.checkName(name);

      // verify unique
      if (byName.get(name) != null)
        throw ArgErr.make("Duplicate thread name: " + name).val;

      // init and put into map
      t.name  = name;
      t.run   = run;
      t.state = NEW;
      byName.put(name, t);
      if (serviceTypes != null) mountService(t, serviceTypes);
    }
  }

  public Thread(String name)
  {
    synchronized (topLock)
    {
      // verify unique
      if (byName.get(name) != null)
        throw ArgErr.make("Duplicate thread name: " + name).val;

      // put into map
      byName.put(name, this);
    }

    this.name  = name;
    this.state = NEW;
  }

  public Thread()
  {
  }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public static Thread find(String name) { return find(name, true); }
  public static Thread find(String name, boolean checked)
  {
    synchronized (topLock)
    {
      Thread thread = (Thread)byName.get(name);
      if (thread != null) return thread;
      if (checked) throw UnknownThreadErr.make(name).val;
      return null;
    }
  }

  public static List list()
  {
    synchronized (topLock)
    {
      return new List(Sys.ThreadType, (Thread[])byName.values().toArray(new Thread[byName.size()])).ro();
    }
  }

  public static Thread current()
  {
    try
    {
      return ((Val)java.lang.Thread.currentThread()).thread;
    }
    catch (ClassCastException e)
    {
      throw Err.make("Current thread not a Fan thread: " + java.lang.Thread.currentThread()).val;
    }
  }

  public static Map locals() { return (Map)locals.get(); }
  private static final ThreadLocal locals = new ThreadLocal()
  {
    protected Object initialValue()
    {
      return new Map(Sys.StrType, Sys.ObjType);
    }
  };

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  public static Thread findService(Type t) { return findService(t.qname(), true); }
  public static Thread findService(Type t, boolean checked) { return findService(t.qname(), checked); }
  static Thread findService(String qname, boolean checked)
  {
    synchronized (topLock)
    {
      ThreadNode node = (ThreadNode)byService.get(qname);
      if (node != null) return node.thread;
      if (checked) throw UnknownThreadErr.make("service: " + qname).val;
      return null;
    }
  }

  public boolean isService()
  {
    return false;
  }

  // must be holding topLock
  static void mountService(Thread thread, List types)
  {
    try
    {
      for (int i=0; i<types.sz(); ++i)
      {
        Type t = (Type)types.get(i);
        if (!isServiceType(t)) continue;
        ThreadNode node = new ThreadNode();
        node.thread = thread;
        ThreadNode x = (ThreadNode)byService.get(t.qname());
        if ( x== null) byService.put(t.qname(), node);
        else
        {
          while (x.next != null) x = x.next;
          x.next = node;
        }
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
  }

  // must be holding topLock
  static void unmountService(Thread thread)
  {
    try
    {
      List types = thread.type().inheritance();
      for (int i=0; i<types.sz(); ++i)
      {
        Type t = (Type)types.get(i);
        if (!isServiceType(t)) continue;
        ThreadNode node = (ThreadNode)byService.get(t.qname());
        ThreadNode last = null;
        while (node.thread != thread) { last = node; node = node.next; }
        if (last == null)
          byService.put(t.qname(), node.next);
        else
          last.next = node.next;
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
  }

  static boolean isServiceType(Type t)
  {
    return t != Sys.ObjType && t != Sys.ThreadType && t.isPublic();
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    return this == obj;
  }

  public final int hashCode()
  {
    return name.hashCode();
  }

  public final long hash()
  {
    return FanStr.hash(name);
  }

  public String toStr()
  {
    return name;
  }

  public Type type()
  {
    return Sys.ThreadType;
  }

  public final String name()
  {
    return name;
  }

  public final void trace()
  {
    java.lang.Thread t = this.val;
    if (t == null) return;
    Err.make("Thread.trace").trace(Sys.out());
  }

  public final void trace(OutStream out)
  {
    java.lang.Thread t = this.val;
    if (t == null) return;
    Err.make("Thread.trace").trace(out);
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public final synchronized boolean isNew()
  {
    return state == NEW;
  }

  public final synchronized boolean isRunning()
  {
    return state == RUNNING;
  }

  public final synchronized boolean isDead()
  {
    return state == DEAD;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public final synchronized Thread start()
  {
    if (state != NEW) throw Err.make("Invalid state for Thread.start").val;
    state = RUNNING;
    val = alloc();
    val.attach(this);
    return this;
  }

  public final synchronized Thread stop()
  {
    if (state == DEAD) return this;
    state = DEAD;
    synchronized (topLock)
    {
      byName.remove(name);
      if (isService()) unmountService(this);
    }
    stopMessages();
    notifyAll();
    if (val != null) val.interrupt();
    return this;
  }

  public final Object join() { return join(null); }
  public final synchronized Object join(Duration duration)
  {
    try
    {
      if (state == NEW) throw Err.make("Thread not started yet").val;

      if (state == RUNNING)
      {
        if (duration != null)
          wait(duration.millis());
        else
          while (state == RUNNING) wait();
      }

      Object r = runResult;
      runResult = null;
      return r;
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
  }

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

//////////////////////////////////////////////////////////////////////////
// Thread Pool
//////////////////////////////////////////////////////////////////////////

  /**
   * Allocate a Java thread to use.  Reuse a lingering thread
   * in the pool if one is available, otherwise create a new one.
   */
  static Val alloc()
  {
    synchronized (topLock)
    {
      if (pool != null)
      {
        Val val = pool;
        val.allocated = true;
        pool = val.next;
        return val;
      }
      else
      {
        return new Val("Idle:" + (totalCount++));
      }
    }
  }

  /**
   * Add a lingering thread to the thread pool.
   */
  static void linger(Val val)
  {
    synchronized (topLock)
    {
      val.allocated = false;
      val.next = pool;
      pool = val;
    }
  }

  /**
   * Free a thread from the thread pool whose linger timeout has expired.
   */
  static void free(Val val)
  {
    synchronized (topLock)
    {
      if (pool == val)
      {
        pool = val.next;
      }
      else
      {
        for (Val p = pool; p != null; p = p.next)
          if (p.next == val) { p.next = p.next.next; break; }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Val
//////////////////////////////////////////////////////////////////////////

  /**
   * Val is the Java thread subclass attached to Fan threads.
   */
  static class Val extends java.lang.Thread
  {
    Val(String name)
    {
      super(name);
      this.unattachedName = name;
      setDaemon(false);
    }

    synchronized void attach(Thread thread)
    {
      this.thread = thread;
      thread.val = this;
      setName(thread.name);
      if (isAlive())
        notifyAll();
      else
        start();
    }

    synchronized void detach()
    {
      thread.val = null;
      thread = null;
      setName(unattachedName);
    }

    public void run()
    {
      while (true)
      {
        // run attached thread
        Thread attached = this.thread;
        try
        {
          Object result = null;
          try
          {
            attached.onStart();
            result = attached.run();
          }
          finally
          {
            attached.onStop();
          }
          synchronized (attached)
          {
            attached.runResult = result;
          }
        }
        catch (TestErr.Val e)
        {
          // suppress testing exceptions
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }

        // attached thread is now dead
        detach();
        attached.stop();

        synchronized (this)
        {
          // add to thread pool
          linger(this);

          // linger for 5sec
          try { wait(5000); } catch (InterruptedException e) {}

          // if still not allocated, then time to die
          if (!allocated)
          {
            free(this);
            return;
          }

          // if we have been allocated, then wait for our
          // next thread to get attached, then do it again!
          while (this.thread == null)
          {
            try { wait(); } catch (InterruptedException e) { e.printStackTrace(); }
          }
        }
      }
    }

    final String unattachedName;  // default thread name
    volatile Thread thread;       // Fan thread
    volatile boolean allocated;   // if allocated during linger
    Val next;                     // thread pool linked list
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  public Object run()
    throws InterruptedException
  {
    if (run != null)
    {
      return run.call1(this);
    }
    else
    {
      System.out.println("WARNING: Thread.run not overridden");
      return null;
    }
  }

  protected void onStart() {}

  protected void onStop() {}

  public final void loop(Func received)
  {
    // ensure only called by myself
    if (current() != this)
      throw Err.make("Thread.current != this").val;

    // ensure received not null
    if (received == null)
      throw NullErr.make("received callback null").val;

    // main loop
    while (state == RUNNING)
    {
      try
      {
        dispatch(received, dequeue());
      }
      catch (Throwable e)
      {
        if (state == RUNNING) e.printStackTrace();
      }
    }
  }

  private void dispatch(Func received, Message msg)
  {
    try
    {
      Object result = received.call1(msg.obj);

      result = Namespace.safe(result);

      msg.finish(MSG_FINISH_OK, result);
    }
    catch (Err.Val e)
    {
      msg.finish(MSG_FINISH_ERR, e.err);
    }
    catch (Throwable e)
    {
      msg.finish(MSG_FINISH_ERR, Err.make(e));
    }
  }

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  public final Object sendSync(Object obj)
  {
    obj = Namespace.safe(obj);

    try
    {
      Message msg = new Message(MSG_SYNC, obj);
      enqueue(msg);
      return msg.waitUntilFinished();
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
  }

  public final Thread sendAsync(Object obj)
  {
    obj = Namespace.safe(obj);

    try
    {
      enqueue(new Message(MSG_ASYNC, obj));
      return this;
    }
    catch (InterruptedException e)
    {
      throw InterruptedErr.make(e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Timer
//////////////////////////////////////////////////////////////////////////

  public final Object sendLater(Duration dur, Object obj) { return sendLater(dur, obj, false); }
  public final Object sendLater(Duration dur, Object obj, boolean repeat)
  {
    obj = Namespace.safe(obj);

    if (dur.ticks <= 0)
      throw ArgErr.make("Invalid duration " + dur).val;

    synchronized (this)
    {
      // find slot in existing timers array
      int id = -1;
      for (int i=0; i<timers.length; ++i)
        if (timers[i] == null) { id = i; break; }

      // grow the timers capacity
      if (id == -1)
      {
        Timer[] temp = new Timer[Math.max(4, timers.length*2)];
        System.arraycopy(timers, 0, temp, 0, timers.length);
        id = timers.length;
        timers = temp;
      }

      // allocate timer structure
      Timer t = new Timer();
      t.deadline = System.nanoTime() + dur.ticks;
      t.duration = repeat ? dur.ticks : -1;
      t.msg = obj;
      timers[id] = t;

      // return ticket which is index into timers array
      return Long.valueOf(id);
    }
  }

  public final void cancelLater(Object ticket)
  {
    synchronized (this)
    {
      try
      {
        timers[((Long)ticket).intValue()] = null;
      }
      catch (Exception e)
      {
        throw ArgErr.make("Invalid ticket").val;
      }
    }
  }

  static class Timer
  {
    long deadline;   // nanoTime expiration
    long duration;   // -1 for non-repeating
    Object msg;         // message to send
  }

//////////////////////////////////////////////////////////////////////////
// Queue
//////////////////////////////////////////////////////////////////////////

  synchronized void stopMessages()
  {
    for (Message m = head; m != null; m = m.next)
      m.finish(MSG_STOPPED, null);
    head = tail = null;
    size = 0;
  }

  synchronized Message dequeue()
    throws InterruptedException
  {
    while (state == RUNNING)
    {
      // check for expired timers
      long now = System.nanoTime();
      long snooze = Long.MAX_VALUE;
      for (int i=0; i<timers.length; ++i)
      {
        Timer timer = timers[i];
        if (timer == null) continue;

        // check if this timer has expired, we use a 10ms
        // fudge factor since most operating system don't
        // have very fine resolution
        long left = timer.deadline - now;
        if (left < 10000000)
        {
          // clear/reset the expired timer
          if (timer.duration > 0)
            timer.deadline = now + timer.duration;
          else
            timers[i] = null;
          return new Message(MSG_ASYNC, timer.msg);
        }

        // update snooze if this our closest expiration
        if (left < snooze) snooze = left;
      }

      // if we don't have any messages, then
      // wait until the closest timer deadline
      if (size != 0) break;
      wait(snooze/1000000L);
    }

    // read message of head of linked list
    Message m = head;
    head = m.next;
    if (head == null) tail = null;
    m.next = null;
    size--;

    // notify enqueue (if blocked on max queue)
    notifyAll();

    // return message
    return m;
  }

  synchronized void enqueue(Message m)
    throws InterruptedException
  {
    // ensure new or running
    if (state > RUNNING)
      throw Err.make("thread not active").val;

    // flow control wait if at max
    if (size >= maxQueueSize) wait();

    // add to tail of linked list
    if (tail == null) { head = tail = m; m.next = null; }
    else { tail.next = m; tail = m; }
    size++;
    if (size > peek) peek = size;

    // notify get thread
    notifyAll();
  }

//////////////////////////////////////////////////////////////////////////
// Message
//////////////////////////////////////////////////////////////////////////

  static class Message
  {
    Message(int state, Object obj)
    {
      this.state = state;
      this.obj = obj;
    }

    synchronized Object waitUntilFinished()
      throws InterruptedException
    {
      if (state == MSG_SYNC) wait();

      switch (state)
      {
        case MSG_SYNC:       throw InterruptedErr.make("sendSync timed out").val;
        case MSG_FINISH_OK:  return obj;
        case MSG_FINISH_ERR: throw Err.make("sendSync failed: " + obj, (Err)obj).val;
        case MSG_STOPPED:    throw InterruptedErr.make("thread stopped").val;
        default: throw new IllegalStateException(""+state);
      }
    }

    void finish(int newState, Object obj)
    {
      if (this.state == MSG_ASYNC)
      {
        if (newState == MSG_FINISH_ERR)
          ((Err)obj).trace();
      }
      else
      {
        synchronized (this)
        {
          this.state = newState;
          this.obj = obj;
          notify();
        }
      }
    }

    int state;       // sync/async in, ok/err out
    Object obj;         // message in, return/err out
    Message next;    // queue linked list
  }

  static final int MSG_ASYNC      = 0;
  static final int MSG_SYNC       = 1;
  static final int MSG_FINISH_OK  = 2;
  static final int MSG_FINISH_ERR = 3;
  static final int MSG_STOPPED    = 4;

//////////////////////////////////////////////////////////////////////////
// State Constants
//////////////////////////////////////////////////////////////////////////

  static final int NEW     = 0;
  static final int RUNNING = 1;
  static final int DEAD    = 2;

//////////////////////////////////////////////////////////////////////////
// ThreadNode
//////////////////////////////////////////////////////////////////////////

  static class ThreadNode
  {
    public String toString() { return thread.toString(); }
    Thread thread;
    ThreadNode next;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static Object topLock = new Object();   // top level lock
  private static HashMap byName = new HashMap();  // String -> Thread
  private static HashMap byService = new HashMap();  // String qname -> ThreadNode
  private static int autoNameCount = 0;           // auto-generate unique name
  private static int totalCount = 0;              // Val unique name
  private static Val pool;                        // thread pool linked list
  private static int maxQueueSize = 1000;         // max messages to queue
  private static Timer[] noTimers = new Timer[0]; // empty timers

  private String name;                  // thread name
  private int state;                 // current state
  private Val val;                   // Java thread if attached
  private Message head, tail;        // message queue linked list
  private int size, peek;            // message queue size
  private Timer[] timers = noTimers; // timers for sendLater
  private Func run;                  // run method
  private Object runResult;          // return of run method

}