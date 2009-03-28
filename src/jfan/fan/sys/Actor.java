//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

import fanx.util.ThreadPool;

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

  public static Actor make(ActorGroup group) { return make(group, null); }
  public static Actor make(ActorGroup group, Func receive)
  {
    Actor self = new Actor();
    make$(self, group, receive);
    return self;
  }

  public static void make$(Actor self, ActorGroup group) { make$(self, group, null); }
  public static void make$(Actor self, ActorGroup group, Func receive)
  {
    // check group
    if (group == null)
      throw NullErr.make("group is null").val;

    // check receive method
    if (receive == null && self.type() == Sys.ActorType)
      throw ArgErr.make("must supply receive func or subclass Actor").val;
    if (receive != null && !receive.isImmutable())
      throw NotImmutableErr.make("Receive func not immutable: " + receive).val;

    // init
    self.group = group;
    self.receive = receive;
  }

  public Actor()
  {
    this.context  = new Context(this);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ActorType; }

//////////////////////////////////////////////////////////////////////////
// Actor
//////////////////////////////////////////////////////////////////////////

  public final ActorGroup group() { return group; }

  public final Future send(Object msg)
  {
    // ensure immutable or safe copy
    msg = Namespace.safe(msg);

    // don't deliver new messages to a stopped group
    if (group.isStopped()) throw Err.make("ActorGroup is stopped").val;

    // get the future instance to manage this message's lifecycle
    Future f = new Future(msg);

    // enqueue the message
    synchronized (lock)
    {
      if (head == null)
      {
        head = tail = f;
        if (!dispatching) group.submit(this);
      }
      else
      {
        tail.next = f;
        tail = f;
      }
    }
    return f;
  }

  public final Future schedule(Duration d, Object msg)
  {
    throw new RuntimeException("TODO");
  }

  protected void onStart(Context cx) {}

  protected void onStop(Context cx) {}

  protected Object receive(Context cx, Object msg)
  {
    if (receive != null) return receive.call2(cx, msg);
    System.out.println("WARNING: " + type() + ".receive not overridden");
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  public final void _work()
  {
    // dequeue everything pending and clear queue
    Future queue = null;
    Context cx = null;
    synchronized (lock)
    {
      queue = head;
      head = tail = null;
      cx = context;
      dispatching = true;
    }

    // dispatch messages
    while (queue != null)
    {
      _dispatch(cx, queue);
      queue = queue.next;
    }

    // done dispatching, if new messages have arrived since
    // we started, submit back to the group for execution
    synchronized (lock)
    {
      dispatching = false;
      if (head != null) group.submit(this);
    }
  }

  final void _dispatch(Context cx, Future msg)
  {
    try
    {
      if (msg.isCancelled()) return;
      if (group.killed) { msg.cancel(); return; }
      msg.set(receive(cx, msg.msg));
    }
    catch (Err.Val e)
    {
      msg.err(e.err);
    }
    catch (Throwable e)
    {
      msg.err(Err.make(e));
    }
  }

  public void _kill()
  {
    // get the pending queue
    Future queue = null;
    synchronized (lock)
    {
      queue = head;
      head = null;
    }

    // cancel all pending messages
    while (queue != null)
    {
      queue.cancel();
      queue = queue.next;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Context context;                 // mutable world state of actor
  private ActorGroup group;              // group controller
  private Func receive;                  // func to invoke on receive or null
  private Object lock = new Object();    // lock for message queue
  private Future head, tail;             // message queue linked list
  private boolean dispatching = false;   // are we currently dispatching

}