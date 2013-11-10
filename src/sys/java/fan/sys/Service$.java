//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;

/**
 * Service mixin implementation methods
 */
public class Service$
{

//////////////////////////////////////////////////////////////////////////
// Registry
//////////////////////////////////////////////////////////////////////////

  private static Object lock = new Object();
  private static HashMap byService = new HashMap();  // Service:State
  private static HashMap byType = new HashMap();     // Type:Node

  public static List list()
  {
    synchronized (lock)
    {
      return new List(Sys.ServiceType, byService.keySet().toArray(new Service[byService.size()]));
    }
  }

  public static Service find(Type t) { return find(t.qname(), true); }
  public static Service find(Type t, boolean checked) { return find(t.qname(), checked); }
  public static Service find(String qname, boolean checked)
  {
    synchronized (lock)
    {
      Node node = (Node)byType.get(qname);
      if (node != null) return node.service;
      if (checked) throw UnknownServiceErr.make(qname);
      return null;
    }
  }

  public static List findAll(Type t)
  {
    String qname = t.qname();
    List list = new List(Sys.ServiceType);
    synchronized (lock)
    {
      Node node = (Node)byType.get(qname);
      while (node != null)
      {
        list.add(node.service);
        node = node.next;
      }
    }
    return list.ro();
  }

  static boolean isServiceType(Type t)
  {
    return t != Sys.ObjType && t != Sys.ServiceType && t.isPublic();
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public static long hash(Service self)
  {
    return System.identityHashCode(self);
  }

  public static boolean equals(Service self, Object that)
  {
    return self == that;
  }

  public static boolean isInstalled(Service self)
  {
    synchronized (lock)
    {
      return byService.get(self) != null;
    }
  }

  public static boolean isRunning(Service self)
  {
    synchronized (lock)
    {
      State state = (State)byService.get(self);
      return state != null && state.running;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public static Service install(Service self)
  {
    try
    {
      List types = FanObj.typeof(self).inheritance();
      synchronized (lock)
      {
        // if already installed, short circuit
        if (self.isInstalled()) return self;

        // add to byService map
        byService.put(self, new State(self));

        // add to map for each type service implements
        for (int i=0; i<types.sz(); ++i)
        {
          Type t = (Type)types.get(i);
          if (!isServiceType(t)) continue;
          Node node = new Node(self);
          Node x = (Node)byType.get(t.qname());
          if (x == null) byType.put(t.qname(), node);
          else
          {
            while (x.next != null) x = x.next;
            x.next = node;
          }
        }
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    return self;
  }

  public static Service uninstall(Service self)
  {
    try
    {
      List types = FanObj.typeof(self).inheritance();
      synchronized (lock)
      {
        // ensure service is stopped
        stop(self);

        // remove from byService map, it not installed short circuit
        if (byService.remove(self) == null) return self;

        // remove from map for each type implemented by service
        nextType: for (int i=0; i<types.sz(); ++i)
        {
          // get next type in inheritance and check if service type
          Type t = (Type)types.get(i);
          if (!isServiceType(t)) continue nextType;

          // lookup linked list for that type
          Node node = (Node)byType.get(t.qname());
          if (node == null) continue nextType;

          // find this thread in the linked list
          Node last = null;
          while (node.service != self)
          {
            last = node;
            node = node.next;
            if (node == null) continue nextType;
          }

          // update the map or linked list
          if (last == null)
            byType.put(t.qname(), node.next);
          else
            last.next = node.next;
        }
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    return self;
  }

  public static Service start(Service self)
  {
    State state = null;
    try
    {
      synchronized (lock)
      {
        // start implies install
        install(self);

        // if already running, short circuit
        state = (State)byService.get(self);
        if (state.running) return self;

        // put into the running state
        state.running = true;
      }

      // onStart callback (outside of lock)
      self.onStart();
    }
    catch (Throwable e)
    {
      if (state != null) state.running = false;
      dumpErr(self, "onStart", e);
    }
    return self;
  }

  public static Service stop(Service self)
  {
    try
    {
      synchronized (lock)
      {
        // if not running, short circuit
        State state = (State)byService.get(self);
        if (state == null || !state.running) return self;

        // take out of the running state
        state.running = false;
      }

      // onStop (outside of lock)
      self.onStop();
    }
    catch (Throwable e)
    {
      dumpErr(self, "onStop", e);
    }
    return self;
  }

  public static void onStart(Service self) {}

  public static void onStop(Service self) {}

  private static void dumpErr(Service self, String method, Throwable e)
  {
    if (e.toString().equals("sys::Err: test-nodump")) return;
    System.out.println("ERROR: " + self.getClass().getName() + "." +  method);
    if (e instanceof Err)
      ((Err)e).trace();
    else
      e.printStackTrace();
  }

//////////////////////////////////////////////////////////////////////////
// State/Node
//////////////////////////////////////////////////////////////////////////

  /** Value for byService map */
  static class State
  {
    State(Service s) { service = s; }
    Service service;
    volatile boolean running;
  }

  /** Value for byType map */
  static class Node
  {
    Node(Service s) { service = s; }
    Service service;
    Node next;
  }

}