//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 09  Brian Frank  Creation
//
package fanx.util;

import java.util.LinkedList;
import java.util.HashMap;
import java.util.Iterator;

/**
 * ThreadPool manages a pool of threads optimized for the Actor framework.
 */
public class ThreadPool
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct with max number of threads.
   */
  public ThreadPool(int max)
  {
    this.max      = max;
    this.idleTime = 5000; // 5sec
    this.idle     = new LinkedList();
    this.pending  = new LinkedList();
    this.workers  = new HashMap(max*3);
    this.state    = RUNNING;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  /**
   * Has this pool been stopped or killed.
   */
  public final boolean isStopped()
  {
    return state != RUNNING;
  }

  /**
   * Has all the work in this queue finished processing and
   * all threads terminated.
   */
  public final boolean isDone()
  {
    if (state == DONE) return true;
    synchronized (this)
    {
      if (state == RUNNING || workers.size() > 0) return false;
      state = DONE;
      return true;
    }
  }

  /**
   * Orderly shutdown of threads.  All pending work items are processed.
   */
  public final void stop()
  {
    state = STOPPING;
  }

  /**
   * Unorderly shutdown of threads.  All pending work are discarded,
   * and interrupt is sent to each thread.
   */
  public final synchronized void kill()
  {
    state = STOPPING;

    // interupt each thread
    Iterator it = workers.values().iterator();
    while (it.hasNext()) ((Worker)it.next()).interrupt();
  }

  /**
   * Wait for all threads to stop.
   ** Return true on success or false on timeout.
   */
  public final synchronized boolean join(long msTimeout)
    throws InterruptedException
  {
    long deadline = System.nanoTime()/1000000L + msTimeout;
    while (true)
    {
      // if all workers have completed, then return success
      if (workers.size() == 0) return true;

      // if we have gone past our deadline, return false
      long toSleep = deadline - System.nanoTime()/1000000L;
      if (toSleep <= 0) return false;

      // sleep until something interesting happens
      wait(toSleep);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Work Management
//////////////////////////////////////////////////////////////////////////

  /**
   * Submit the given work to be run by a thread in this pool.
   * If an idle thread is available, the work is immediately
   * run.  If no idle threads are available, but the current number
   * of threads is less than max, then launch a new thread to
   * execute the work.  If the current number of threads is at
   * max, then queue the work until a thread becomes available.
   */
  public synchronized void submit(Work work)
  {
    // if we have an idle thread, use it
    Worker worker = (Worker)idle.poll();
    if (worker != null)
    {
      worker.run(work);
      return;
    }

    // if we are below max, then spawn a new thread
    if (workers.size() < max)
    {
      worker = new Worker("ThreadPool-Worker-" + (counter++), work);
      worker.start();
      workers.put(worker, worker);
      return;
    }

    // queue the runnable until we have an idle thread
    pending.addLast(work);
  }

  /**
   * This is called by a worker when it completes a work item.
   * If there is pending work return it.  Otherwise if idle time
   * is over then free the worker and let it die. If idle time is
   * not over then put the worker into our idle queue.
   */
  synchronized Work ready(Worker w, boolean idleTimeOver)
  {
    // if we have a pending work, then immediately reuse the worker
    Work work = (Work)pending.poll();
    if (work != null) return work;

    // if the worker's idle time is over or we are
    // shutting down, then free the worker and let it die
    if (idleTimeOver || state != RUNNING)
    {
      idle.remove(w);
      workers.remove(w);
      notifyAll();
      return null;
    }

    // add to head of idle list (we let oldest threads die out first)
    idle.addFirst(w);
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  public void dump(fan.sys.List args)
  {
    fan.sys.OutStream out = fan.sys.Sys.out();
    if (args != null && args.size() > 0)
      out = (fan.sys.OutStream)args.get(0);

    out.printLine("ThreadPool");
    out.printLine("  pending: " + pending.size());
    out.printLine("  idle:    " + idle.size());
    out.printLine("  workers: " + workers.size());
    Iterator it = workers.values().iterator();
    while (it.hasNext())
    {
      Worker w = (Worker)it.next();
      out.printLine("  " + w + "  " + w.work);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Worker
//////////////////////////////////////////////////////////////////////////

  /**
   * Worker is a reusable thread within the thread pool.
   */
  class Worker extends Thread
  {
    /**
     * Construct with name and initial work to execute.
     */
    Worker(String name, Work work)
    {
      super(name);
      this.work = work;
    }

    /**
     * Equality must be reference for storage in a hash table.
     */
    public final boolean equals(Object o)
    {
      return this == o;
    }

    /**
     * A worker thread loops repeatly executing work until it times out.
     */
    public void run()
    {
      try
      {
        // loop processing runnables
        while (true)
        {
          // execute work
          try { work._work(); } catch (Throwable e) { e.printStackTrace(); }
          work = null;

          // once I am finished this work, I need to
          // get more work or enter an idle state
          synchronized (this)
          {
            // let the thread pool know I am idle, if it has pending
            // work for me, then immediately execute it
            work = ready(this, false);
            if (work != null) continue;

            // idle this thread for a period of time to
            // see if any new work becomes available
            try { wait(idleTime); } catch (InterruptedException e) {}

            // if work was given to me while I was waiting, then do it
            if (work != null) continue;

            // check back again for pending work but this time pass true for
            // idleTimeOver, if still no work for me then it is time to die
            work = ready(this, true);
            if (work == null) return;
          }
        }
      }
      catch (Throwable e)
      {
        // if an exception is raised we have serious problems
        e.printStackTrace();
      }
    }

    /**
     * Give this thread a work item and wake it up from its idle state.
     * This method should never be called unless in the idle state.
     */
    public synchronized void run(Work work)
    {
      this.work = work;
      notifyAll();
    }

    private Work work;
  }

//////////////////////////////////////////////////////////////////////////
// Work
//////////////////////////////////////////////////////////////////////////

  /**
   * Item of work to execute in the thread pool.
   * Note: method _work() is used so we don't polluate Actor's namespace.
   */
  public static interface Work
  {
    public void _work();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final int RUNNING  = 0;
  static final int STOPPING = 1;
  static final int DONE     = 2;

  final int max;               // maximum number of threads to use
  final int idleTime;          // time in ms to let threads idle (5sec)
  private volatile int state;  // life cycle state
  private LinkedList idle;     // idle threads waiting for work
  private LinkedList pending;  // pending working we don't have threads for yet
  private HashMap workers;     // map of all worker threads
  private int counter;         // counter for all threads ever created
}