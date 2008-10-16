//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Feb 07  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading;
using NThread = System.Threading.Thread;
using ThreadPool = System.Threading.ThreadPool;
using ThreadInterruptedException = System.Threading.ThreadInterruptedException;

namespace Fan.Sys
{
  /// <summary>
  /// Thread models a thread of execution within a process.
  /// </summary>
  public class Thread : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Thread make() { return make(null, null); }
    public static Thread make(Str name) { return make(name, null); }
    public static Thread make(Str name, Func run)
    {
      Thread t = new Thread();
      make_(t, name, run);
      return t;
    }

    public static void make_(Thread t) { make_(t, null, null); }
    public static void make_(Thread t, Str name) { make_(t, name, null); }
    public static void make_(Thread t, Str name, Func run)
    {
      // if service, get inheritance types before acquiring lock
      List serviceTypes = null;
      if (t.isService().booleanValue())
        serviceTypes = t.type().inheritance();

      lock (topLock)
      {
        // check run method
        if (run != null && !run.isImmutable().booleanValue())
          throw NotImmutableErr.make("Run method not const: " + run).val;

        // auto generate name if null
        if (name == null)
          name = Str.make(t.type().pod().name() + "." + t.type().name() + "." + (autoNameCount++));

        // verify name is valid
        Uri.checkName(name);

        // verify unique
        if (byName[name] != null)
          throw ArgErr.make("Duplicate thread name: " + name).val;

        // init and put into map
        t.m_name  = name;
        t.m_run   = run;
        t.m_state = NEW;
        byName[name] = t;
        if (serviceTypes != null) mountService(t, serviceTypes);
      }
    }

    public Thread(string name)
    {
      this.m_name  = Str.make(name);
      this.m_state = NEW;
    }

    public Thread(Str name)
    {
      lock (topLock)
      {
        // verify unique
        if (byName[name] != null)
          throw ArgErr.make("Duplicate thread name: " + name).val;

        // put into map
        byName[name] = this;
      }

      this.m_name  = name;
      this.m_state = NEW;
    }

    public Thread()
    {
    }

    static Thread()
    {
      // TODO - not sure what these values should be yet (they default to 2/2)

      // it takes like half a second to spawn a new thread if we exceed
      // the min tread count in the ThreadPool, which throws off all the
      // timing in sysTest::ThreadTest - so for the time being set to 5
      ThreadPool.SetMinThreads(5, 2);
    }

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Thread find(Str name) { return find(name, Boolean.True); }
    public static Thread find(Str name, Boolean check)
    {
      lock (topLock)
      {
        Thread thread = (Thread)byName[name];
        if (thread != null) return thread;
        if (check.booleanValue()) throw UnknownThreadErr.make(name).val;
        return null;
      }
    }

    public static List list()
    {
      lock (topLock)
      {
        Thread[] arr = new Thread[byName.Count];
        byName.Values.CopyTo(arr, 0);
        return new List(Sys.ThreadType, arr).ro();
      }
    }

    public static Thread current()
    {
      if (m_threadLookup == null)
        throw Err.make("Current thread not a Fan thread: " + NThread.CurrentThread).val;
      return m_threadLookup;
    }

    public static Map locals()
    {
      if (m_locals == null) m_locals = new Map(Sys.StrType, Sys.ObjType);
      return m_locals;
    }

    [ThreadStatic] static Map m_locals;
    [ThreadStatic] static Thread m_threadLookup;

  //////////////////////////////////////////////////////////////////////////
  // Service
  //////////////////////////////////////////////////////////////////////////

    public static Thread findService(Type t) { return findService(t.qname().val, true); }
    public static Thread findService(Type t, Boolean check) { return findService(t.qname().val, check.booleanValue()); }
    public static Thread findService(String qname, bool check)
    {
      lock (topLock)
      {
        ThreadNode node = (ThreadNode)byService[qname];
        if (node != null) return node.thread;
        if (check) throw UnknownThreadErr.make("service: " + qname).val;
        return null;
      }
    }

    public virtual Boolean isService()
    {
      return Boolean.False;
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
          ThreadNode x = (ThreadNode)byService[t.qname().val];
          if ( x== null) byService[t.qname().val] = node;
          else
          {
            while (x.next != null) x = x.next;
            x.next = node;
          }
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
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
          ThreadNode node = (ThreadNode)byService[t.qname().val];
          ThreadNode last = null;
          while (node.thread != thread) { last = node; node = node.next; }
          if (last == null)
            byService[t.qname().val] = node.next;
          else
            last.next = node.next;
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
    }

    static bool isServiceType(Type t)
    {
      return t != Sys.ObjType && t != Sys.ThreadType && t.isPublic().booleanValue();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Boolean _equals(object obj)
    {
      return this == obj ? Boolean.True : Boolean.False;
    }

    public override int GetHashCode()
    {
      return m_name.GetHashCode();
    }

    public override Int hash()
    {
      return m_name.hash();
    }

    public override Str toStr()
    {
      return m_name;
    }

    public override Type type()
    {
      return Sys.ThreadType;
    }

    public Str name()
    {
      return m_name;
    }

    public void trace() { trace(Sys.@out()); }
    public void trace(OutStream @out)
    {
      if (m_thread == null) return;

      @out.printLine(Str.make("sys::Err: Thread.trace"));

      StackTrace st = new StackTrace(true);
      for(int i=1; i<st.FrameCount; i++)
      {
        StackFrame sf = st.GetFrame(i);
        MethodBase mb = sf.GetMethod();
        string loc = sf.GetFileName();

        // remove the filepath if it exists
        if (loc == null) loc = "Unknown";
        else
        {
          int index = loc.LastIndexOf("\\");
          if (index != -1) loc = loc.Substring(index+1);
          loc += ":" + sf.GetFileLineNumber();
        }

        // convert to Fan type
        string type = mb.ReflectedType.ToString();
        if (type.StartsWith("Fan."))
        {
          int off = type.IndexOf(".", 4);
          string pod = type.Substring(4, off-4);
          string fant = type.Substring(off+1);
          type = Str.make(pod).decapitalize().val + "::" + fant;
        }

        StringBuilder sb = new StringBuilder();
        sb.Append("  ").Append(type).Append(".").Append(mb.Name);
        sb.Append(" (").Append(loc).Append(")");
        @out.printLine(Str.make(sb.ToString()));
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Boolean isNew()
    {
      return Boolean.valueOf(m_state == NEW);
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Boolean isRunning()
    {
      return Boolean.valueOf(m_state == RUNNING);
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Boolean isDead()
    {
      return Boolean.valueOf(m_state == DEAD);
    }

  //////////////////////////////////////////////////////////////////////////
  // Lifecycle
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Thread start()
    {
      if (m_state != NEW) throw Err.make("Invalid state for Thread.start").val;
      m_state = RUNNING;
      ThreadPool.QueueUserWorkItem(new WaitCallback(doRun), this);
      return this;
    }

    private static void doRun(object state)
    {
      // run attached thread
      Thread attached = state as Thread;
//System.Console.WriteLine(" >>> " + attached.m_name + ": doRun() on " +  NThread.CurrentThread.ManagedThreadId);
      attached.m_thread = NThread.CurrentThread;
      m_threadLookup = attached;
      try
      {
        object result = null;
        try
        {
          attached.onStart();
          result = attached.run();
        }
        finally
        {
          attached.onStop();
        }
        lock (attached)
        {
          attached.m_runResult = result;
        }
      }
      catch (TestErr.Val)
      {
        // suppress testing exceptions
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }

      // attached thread is now dead
      m_threadLookup = null;
      attached.m_thread = null;
      attached.stop();
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Thread stop()
    {
      if (m_state == DEAD) return this;
      m_state = DEAD;
      lock (topLock)
      {
        byName.Remove(m_name);
        if (isService().booleanValue()) unmountService(this);
      }
      stopMessages();
      Monitor.PulseAll(this);
      if (m_thread != null) m_thread.Interrupt();
      return this;
    }

    public object join() { return join(null); }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public object join(Duration duration)
    {
      try
      {
        if (m_state == NEW) throw Err.make("Thread not started yet").val;

        if (m_state == RUNNING)
        {
          if (duration != null)
            Monitor.Wait(this, (int)duration.millis());
          else
            while (m_state == RUNNING) Monitor.Wait(this);
        }

        object r = m_runResult;
        m_runResult = null;
        return r;
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
    }

    public static void sleep(Duration duration)
    {
      try
      {
        NThread.Sleep((int)duration.millis());
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Runner
  //////////////////////////////////////////////////////////////////////////

    static void runner(object state)
    {
      // TODO
    }

  //////////////////////////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////////////////////////

    public virtual object run()
    {
      if (m_run != null)
      {
        return m_run.call1(this);
      }
      else
      {
        System.Console.WriteLine("WARNING: Thread.run not overridden");
        return null;
      }
    }

    protected void onStart() {}

    protected void onStop() {}

    public void loop(Func received)
    {
      // ensure only called by myself
      if (current() != this)
        throw Err.make("Thread.current != this").val;

      // ensure received not null
      if (received == null)
        throw NullErr.make("received callback null").val;

      // main loop
      while (m_state == RUNNING)
      {
        try
        {
          dispatch(received, dequeue());
        }
        catch (Exception e)
        {
          if (m_state == RUNNING) Err.dumpStack(e);
        }
      }
    }

    private void dispatch(Func received, Message msg)
    {
      try
      {
        object result = received.call1(msg.obj);
        result = Namespace.safe(result);
        msg.finish(MSG_FINISH_OK, result);
      }
      catch (Err.Val e)
      {
        msg.finish(MSG_FINISH_ERR, e.m_err);
      }
      catch (Exception e)
      {
        msg.finish(MSG_FINISH_ERR, Err.make(e));
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Messaging
  //////////////////////////////////////////////////////////////////////////

    public object sendSync(object obj)
    {
      obj = Namespace.safe(obj);

      try
      {
        Message msg = new Message(MSG_SYNC, obj);
        enqueue(msg);
        return msg.waitUntilFinished();
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
    }

    public Thread sendAsync(object obj)
    {
      obj = Namespace.safe(obj);

      try
      {
        enqueue(new Message(MSG_ASYNC, obj));
        return this;
      }
      catch (ThreadInterruptedException e)
      {
        throw InterruptedErr.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Timer
  //////////////////////////////////////////////////////////////////////////

    public object sendLater(Duration dur, object obj) { return sendLater(dur, obj, Boolean.False); }
    public object sendLater(Duration dur, object obj, Boolean repeat)
    {
      obj = Namespace.safe(obj);

      if (dur.m_ticks <= 0)
        throw ArgErr.make("Invalid duration " + dur).val;

      lock (this)
      {
        // find slot in existing timers array
        int id = -1;
        for (int i=0; i<m_timers.Length; ++i)
          if (m_timers[i] == null) { id = i; break; }

        // grow the timers capacity
        if (id == -1)
        {
          Timer[] temp = new Timer[Math.Max(4, m_timers.Length*2)];
          Array.Copy(m_timers, 0, temp, 0, m_timers.Length);
          id = m_timers.Length;
          m_timers = temp;
        }

        // allocate timer structure
        Timer t = new Timer();
        t.deadline = Sys.ticks() + dur.m_ticks;
        t.duration = repeat.booleanValue() ? dur.m_ticks : -1;
        t.msg = obj;
        m_timers[id] = t;

        // return ticket which is index into timers array
        return Int.make(id);
      }
    }

    public void cancelLater(object ticket)
    {
      lock (this)
      {
        try
        {
          m_timers[(int)((Int)ticket).val] = null;
        }
        catch (Exception)
        {
          throw ArgErr.make("Invalid ticket").val;
        }
      }
    }

    internal class Timer
    {
      internal long deadline;   // nanoTime expiration
      internal long duration;   // -1 for non-repeating
      internal object msg;         // message to send
    }

  //////////////////////////////////////////////////////////////////////////
  // Queue
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    void stopMessages()
    {
      for (Message m = m_head; m != null; m = m.next)
        m.finish(MSG_STOPPED, null);
      m_head = m_tail = null;
      m_size = 0;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    Message dequeue()
    {
      while (m_state == RUNNING)
      {
        // check for expired timers
        long now = Sys.ticks();
        long snooze = Int64.MaxValue;
        for (int i=0; i<m_timers.Length; ++i)
        {
          Timer timer = m_timers[i];
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
              m_timers[i] = null;
            return new Message(MSG_ASYNC, timer.msg);
          }

          // update snooze if this our closest expiration
          if (left < snooze) snooze = left;
        }

        // if we don't have any messages, then
        // wait until the closest timer deadline
        if (m_size != 0) break;
        Monitor.Wait(this, (int)(snooze/1000000L));
      }

      // read message of head of linked list
      Message m = m_head;
      m_head = m.next;
      if (m_head == null) m_tail = null;
      m.next = null;
      m_size--;

      // notify enqueue in case blocked on max
      Monitor.Pulse(this);

      // return message
      return m;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    void enqueue(Message m)
    {
      // ensure new or running
      if (m_state > RUNNING)
        throw Err.make("thread not active").val;

      // flow control wait if at max
      if (m_size >= maxQueueSize) Monitor.Wait(this);

      // add to tail of linked list
      if (m_tail == null) { m_head = m_tail = m; m.next = null; }
      else { m_tail.next = m; m_tail = m; }
      m_size++;
      if (m_size > m_peek) m_peek = m_size;

      // notify get thread
      Monitor.Pulse(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Message
  //////////////////////////////////////////////////////////////////////////

    internal class Message
    {
      public Message(int state, object obj)
      {
        this.state = state;
        this.obj = obj;
      }

      [MethodImpl(MethodImplOptions.Synchronized)]
      internal object waitUntilFinished()
      {
        if (state == MSG_SYNC) Monitor.Wait(this);

        switch (state)
        {
          case MSG_SYNC:       throw InterruptedErr.make("sendSync timed out").val;
          case MSG_FINISH_OK:  return obj;
          case MSG_FINISH_ERR: throw ((Err)obj).val;
          case MSG_STOPPED:    throw InterruptedErr.make("thread stopped").val;
          default: throw new Exception(""+state);
        }
      }

      internal void finish(int newState, object obj)
      {
        if (this.state == MSG_ASYNC)
        {
          if (newState == MSG_FINISH_ERR)
            ((Err)obj).trace();
        }
        else
        {
          lock (this)
          {
            this.state = newState;
            this.obj = obj;
            Monitor.Pulse(this);
          }
        }
      }

      internal int state;       // sync/async in, ok/err out
      internal object obj;         // message in, return/err out
      internal Message next;    // queue linked list
    }

    const int MSG_ASYNC      = 0;
    const int MSG_SYNC       = 1;
    const int MSG_FINISH_OK  = 2;
    const int MSG_FINISH_ERR = 3;
    const int MSG_STOPPED    = 4;

  //////////////////////////////////////////////////////////////////////////
  // State Constants
  //////////////////////////////////////////////////////////////////////////

    const int NEW     = 0;
    const int RUNNING = 1;
    const int DEAD    = 2;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static object topLock = new object();   // top level lock
    private static Hashtable byName = new Hashtable();  // String -> Thread
    private static Hashtable byService = new Hashtable();  // String -> ThreadNode
    private static int autoNameCount = 0;           // auto-generate unique name
    private static int maxQueueSize = 1000;         // max messages to queue
    private static Timer[] noTimers = new Timer[0]; // empty timers

    private Str m_name;                  // thread name
    private int m_state;                 // current state
    private NThread m_thread;            // .NET thread if attached
    private Message m_head, m_tail;      // message queue linked list
    private int m_size, m_peek;          // message queue size
    private Timer[] m_timers = noTimers; // timers for sendLater
    private Func m_run;                  // run method
    private object m_runResult;             // return of run method

  }

//////////////////////////////////////////////////////////////////////////
// ThreadNode
//////////////////////////////////////////////////////////////////////////

  class ThreadNode
  {
    override public String ToString() { return thread.ToString(); }
    public Thread thread;
    public ThreadNode next;
  }

}