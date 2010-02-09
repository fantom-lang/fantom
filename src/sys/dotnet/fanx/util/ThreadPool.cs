//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;

namespace Fanx.Util
{
  /// <summary>
  /// ThreadPool manages a pool of threads optimized for the Actor framework.
  /// </summary>
  public class ThreadPool
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Construct with max number of threads.
    /// </summary>
    public ThreadPool(int max)
    {
      this.max      = max;
      this.idleTime = 5000; // 5sec
      this.idle     = new LinkedList<Worker>();
      this.pending  = new LinkedList<Work>();
      this.workers  = new Hashtable(max*3);
      this.state    = RUNNING;
    }

  //////////////////////////////////////////////////////////////////////////
  // Lifecycle
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Has this pool been stopped or killed.
    /// </summary>
    public bool isStopped()
    {
      return state != RUNNING;
    }

    /// <summary>
    /// Has all the work in this queue finished processing and
    /// all threads terminated.
    /// </summary>
    public bool isDone()
    {
      if (state == DONE) return true;
      lock (this)
      {
        if (state == RUNNING || workers.Count > 0) return false;
        state = DONE;
        return true;
      }
    }

    /// <summary>
    /// Orderly shutdown of threads.  All pending work items are processed.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void stop()
    {
      state = STOPPING;

      // immediately wake up all the idle workers so they can die
      while (true)
      {
        LinkedListNode<Worker> node = idle.First;
        if (node == null) break;
        Worker w = (Worker)node.Value;
        idle.RemoveFirst();
        w.run(null);
      }
    }

    /// <summary>
    /// Unorderly shutdown of threads.  All pending work are discarded,
    /// and interrupt is sent to each thread.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void kill()
    {
      state = STOPPING;

      // kill all the pending work
      while (true)
      {
        LinkedListNode<Work> node = pending.First;
        if (node == null) break;
        Work work = (Work)node.Value;
        pending.RemoveFirst();
        work._kill();
      }

      // interupt each thread
      IEnumerator en = workers.Values.GetEnumerator();
      while (en.MoveNext()) ((Worker)en.Current).thread.Interrupt();
    }

    /// <summary>
    /// Wait for all threads to stop.
    /// Return true on success or false on timeout.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public bool join(long msTimeout)
    {
      long deadline = Fan.Sys.Sys.nanoTime()/1000000L + msTimeout;
      while (true)
      {
        // if all workers have completed, then return success
        if (workers.Count == 0) return true;

        // if we have gone past our deadline, return false
        long toSleep = deadline - Fan.Sys.Sys.nanoTime()/1000000L;
        if (toSleep <= 0) return false;

        // sleep until something interesting happens
        Monitor.Wait(this, (int)toSleep);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Work Management
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Submit the given work to be run by a thread in this pool.
    /// If an idle thread is available, the work is immediately
    /// run.  If no idle threads are available, but the current number
    /// of threads is less than max, then launch a new thread to
    /// execute the work.  If the current number of threads is at
    /// max, then queue the work until a thread becomes available.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void submit(Work work)
    {
      // if we have an idle thread, use it
      LinkedListNode<Worker> node = idle.First;
      if (node != null)
      {
        Worker worker = (Worker)node.Value;
        idle.RemoveFirst();
        worker.run(work);
        return;
      }

      // if we are below max, then spawn a new thread
      if (workers.Count < max)
      {
        Worker worker = new Worker(this, work);
        Thread thread = new Thread(worker.run);
        thread.Name = "ThreadPool-Worker-" + (counter++);
        worker.thread = thread;
        thread.Start();
        workers[worker] = worker;
        return;
      }

      // queue the runnable until we have an idle thread
      pending.AddLast(work);
    }

    /// <summary>
    /// This is called by a worker when it completes a work item.
    /// If there is pending work return it.  Otherwise if idle time
    /// is over then free the worker and let it die. If idle time is
    /// not over then put the worker into our idle queue.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    internal Work ready(Worker w, bool idleTimeOver)
    {
      // if we have a pending work, then immediately reuse the worker
      LinkedListNode<Work> node = pending.First;
      if (node != null)
      {
        pending.RemoveFirst();
        return node.Value;
      }

      // if the worker's idle time is over or we are
      // shutting down, then free the worker and let it die
      if (idleTimeOver || state != RUNNING)
      {
        free(w);
        return null;
      }

      // add to head of idle list (we let oldest threads die out first)
      idle.AddFirst(w);
      return null;
    }

    /// <summary>
    /// Free worker from all data structures and let it die.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    internal void free(Worker w)
    {
      idle.Remove(w);
      workers.Remove(w);
      Monitor.PulseAll(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Debug
  //////////////////////////////////////////////////////////////////////////

    public void dump(Fan.Sys.List args)
    {
      Fan.Sys.OutStream @out = Fan.Sys.Env.cur().@out();
      if (args != null && args.size() > 0)
        @out = (Fan.Sys.OutStream)args.get(0);

      @out.printLine("ThreadPool");
      @out.printLine("  pending: " + pending.Count);
      @out.printLine("  idle:    " + idle.Count);
      @out.printLine("  workers: " + workers.Count);
      IEnumerator en = workers.Values.GetEnumerator();
      while (en.MoveNext())
      {
        Worker w = (Worker)en.Current;
        @out.printLine("  " + w + "  " + w.work);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Worker
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Worker is a reusable thread within the thread pool.
    /// </summary>
    internal class Worker
    {
      /// <summary>
      /// Construct with name and initial work to execute.
      /// </summary>
      public Worker(ThreadPool pool, Work work)
      {
        this.pool = pool;
        this.work = work;
      }

      /// <summary>
      /// Equality must be reference for storage in a hash table.
      /// </summary>
      public bool equals(object o)
      {
        return this == o;
      }

      /// <summary>
      /// A worker thread loops repeatly executing work until it times out.
      /// </summary>
      public void run()
      {
        try
        {
          // loop processing runnables
          while (true)
          {
            // execute work
            try { work._work(); } catch (System.Exception e) { Fan.Sys.Err.dumpStack(e); }
            work = null;

            // once I am finished this work, I need to
            // get more work or enter an idle state
            lock (this)
            {
              // let the thread pool know I am idle, if it has pending
              // work for me, then immediately execute it
              work = pool.ready(this, false);
              if (work != null) continue;

              // idle this thread for a period of time to
              // see if any new work becomes available
              try { Monitor.Wait(this, pool.idleTime); } catch (ThreadInterruptedException) {}

              // if work was given to me while I was waiting, then do it
              if (work != null) continue;

              // check back again for pending work but this time pass true for
              // idleTimeOver, if still no work for me then it is time to die
              work = pool.ready(this, true);
              if (work == null) return;
            }
          }
        }
        catch (System.Exception e)
        {
          // if an exception is raised, free worker
          Fan.Sys.Err.dumpStack(e);
          pool.free(this);
        }
      }

      /// <summary>
      /// Give this thread a work item and wake it up from its idle state.
      /// This method should never be called unless in the idle state.
      /// </summary>
      [MethodImpl(MethodImplOptions.Synchronized)]
      public void run(Work work)
      {
        this.work = work;
        Monitor.PulseAll(this);
      }

      internal ThreadPool pool;
      internal Thread thread;
      internal Work work;
    }

  //////////////////////////////////////////////////////////////////////////
  // Work
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Item of work to execute in the thread pool.
    /// Note: method _work() is used so we don't polluate Actor's namespace.
    /// </summary>
    public interface Work
    {
      void _work();
      void _kill();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    const int RUNNING  = 0;
    const int STOPPING = 1;
    const int DONE     = 2;

    internal readonly int max;         // maximum number of threads to use
    internal readonly int idleTime;    // time in ms to let threads idle (5sec)
    private volatile int state;        // life cycle state
    private LinkedList<Worker> idle;   // idle threads waiting for work
    private LinkedList<Work> pending;  // pending working we don't have threads for yet
    private Hashtable workers;         // map of all worker threads
    private int counter;               // counter for all threads ever created
  }
}