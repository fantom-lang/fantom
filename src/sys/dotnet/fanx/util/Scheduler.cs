//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System.Runtime.CompilerServices;
using System.Threading;

namespace Fanx.Util
{
  /// <summary>
  /// Scheduler is used to schedule work to be run after an elapsed
  /// period of time.  It is optimized for use with the actor framework.
  /// Scheduler lazily launches a background thread the first time an
  /// item of work is scheduled.
  /// </summary>
  public class Scheduler
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Constructor.
    /// </summary>
    public Scheduler()
    {
      this.alive = true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Public
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Schedule the work item to be executed after
    /// the given duration of nanoseconds has elapsed.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void schedule(long ns, Work work)
    {
      // insert into our linked list
      bool newHead = add(ns, work);

      // if we haven't launched our thread yet, then launch it
      if (thread == null)
      {
        thread = new Thread(run);
        thread.Name = "Scheduler";
        thread.Start();
      }

      // if we added to the head of our linked list, then we
      // modified our earliest deadline, so we need to notify thread
      if (newHead) Monitor.PulseAll(this);
    }

    /// <summary>
    /// Add the work item into the linked list so that the list
    /// is always sorted by earliest deadline to oldest deadline.
    /// Return true if we have a new head which changes our
    /// next earliest deadline.
    /// </summary>
    private bool add(long ns, Work work)
    {
      // create new node for our linked list
      Node node = new Node();
      node.deadline = Fan.Sys.Sys.nanoTime() + ns;
      node.work = work;

      // if no items, this is easy
      if (head == null)
      {
        head = node;
        return true;
      }

      // if new item has earliest deadline it becomes new head
      if (node.deadline < head.deadline)
      {
        node.next = head;
        head = node;
        return true;
      }

      // find insertion point in linked list
      Node last = head, cur = head.next;
      while (cur != null)
      {
        if (node.deadline < cur.deadline)
        {
          node.next = cur;
          last.next = node;
          return false;
        }

        last = cur;
        cur = cur.next;
      }

      // this node has the oldest deadline, append to linked list
      last.next = node;
      return false;
    }

    /// <summary>
    /// Stop the background thread and call cancel
    /// on all pending work items.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public void stop()
    {
      // kill background thread
      alive = false;
      try { thread.Interrupt(); } catch (System.Exception) {}

      // call cancel on everything in queue
      Node node = head;
      while (node != null)
      {
        try { node.work.cancel(); } catch (System.Exception e) { Fan.Sys.Err.dumpStack(e); }
        node = node.next;
      }

      // clear queue
      head = null;
    }

    /// <summary>
    /// Debug
    /// </summary>
    public void dump()
    {
      for (Node n = head; n != null; n = n.next)
        System.Console.WriteLine("  " + n);
    }

  //////////////////////////////////////////////////////////////////////////
  // Thread
  //////////////////////////////////////////////////////////////////////////

    public void run()
    {
      while (alive)
      {
        try
        {
          Work work = null;
          lock (this)
          {
            // if no work ready to go, then wait for next deadline
            long now = Fan.Sys.Sys.nanoTime();
            if (head == null || head.deadline > now)
            {
              long toSleep = head != null ? head.deadline - now : System.Int64.MaxValue;
              System.TimeSpan ts = new System.TimeSpan(toSleep/100);
              if (ts.TotalMilliseconds > System.Int32.MaxValue)
                Monitor.Wait(this, System.Int32.MaxValue);
              else
                Monitor.Wait(this, ts);
              continue;
            }

            // dequeue the next work item while holding lock
            work = head.work;
            head = head.next;
          }

          // work callback
          work.work();
        }
        catch (System.Exception e)
        {
          if (alive) Fan.Sys.Err.dumpStack(e);
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Node (linked list of work)
  //////////////////////////////////////////////////////////////////////////

    internal class Node
    {
      public string tostring()
      {
        long ms = (deadline - Fan.Sys.Sys.nanoTime()) / 1000000L;
        return "Deadline: " + ms + "ms  Work: " + work;
      }

      internal long deadline;   // System.nanoTime
      internal Work work;       // item of work to execute
      internal Node next;       // next node in linked list
    }

  //////////////////////////////////////////////////////////////////////////
  // Work (item of work to be scheduled)
  //////////////////////////////////////////////////////////////////////////

    public interface Work
    {
      void work();
      void cancel();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    volatile bool alive;     // is this scheduler alive
    Thread thread;           // thread currently being used
    Node head;               // linked list sorted by deadline
  }
}