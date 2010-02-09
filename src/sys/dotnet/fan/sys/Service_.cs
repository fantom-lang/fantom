//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// Service mixin implementation methods.
  /// </summary>
  public class Service_
  {

  //////////////////////////////////////////////////////////////////////////
  // Registry
  //////////////////////////////////////////////////////////////////////////

    private static object m_lock = new object();
    private static Hashtable byService = new Hashtable();  // Service:State
    private static Hashtable byType = new Hashtable();     // Type:Node

    public static List list()
    {
      lock (m_lock)
      {
        Service[] array = new Service[byService.Count];
        byService.Keys.CopyTo(array, 0);
        return new List(Sys.ServiceType, array);
      }
    }

    public static Service find(Type t) { return find(t.qname(), true); }
    public static Service find(Type t, bool check) { return find(t.qname(), check); }
    public static Service find(string qname, bool check)
    {
      lock (m_lock)
      {
        Node node = (Node)byType[qname];
        if (node != null) return node.service;
        if (check) throw UnknownServiceErr.make(qname).val;
        return null;
      }
    }

    public static List findAll(Type t)
    {
      string qname = t.qname();
      List list = new List(Sys.ServiceType);
      lock (m_lock)
      {
        Node node = (Node)byType[qname];
        while (node != null)
        {
          list.add(node.service);
          node = node.next;
        }
      }
      return list.ro();
    }

    static bool isServiceType(Type t)
    {
      return t != Sys.ObjType && t != Sys.ServiceType && t.isPublic();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static long hash(Service self)
    {
      return Env.cur().idHash(self);
    }

    // TODO - there appears to be a bug in my
    // emit code that mixins look for this method
    // on the impl class
    public static bool Equals(Service self, object that)
    {
      return self == that;
    }

    public static bool equals(Service self, object that)
    {
      return self == that;
    }

    public static bool isInstalled(Service self)
    {
      lock (m_lock)
      {
        return byService[self] != null;
      }
    }

    public static bool isRunning(Service self)
    {
      lock (m_lock)
      {
        State state = (State)byService[self];
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
        List types = FanObj.@typeof(self).inheritance();
        lock (m_lock)
        {
          // if already installed, short circuit
          if (self.isInstalled()) return self;

          // add to byService map
          byService[self] = new State(self);

          // add to map for each type service implements
          for (int i=0; i<types.sz(); ++i)
          {
            Type t = (Type)types.get(i);
            if (!isServiceType(t)) continue;
            Node node = new Node(self);
            Node x = (Node)byType[t.qname()];
            if (x == null) byType[t.qname()] = node;
            else
            {
              while (x.next != null) x = x.next;
              x.next = node;
            }
          }
        }
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
      }
      return self;
    }

    public static Service uninstall(Service self)
    {
      try
      {
        List types = FanObj.@typeof(self).inheritance();
        lock (m_lock)
        {
          // ensure service is stopped
          stop(self);

          // remove from byService map, it not installed short circuit
          if (byService[self] == null) return self;
          byService.Remove(self);

          // remove from map for each type implemented by service
          for (int i=0; i<types.sz(); ++i)
          {
            // get next type in inheritance and check if service type
            Type t = (Type)types.get(i);
            if (!isServiceType(t)) continue;

            // lookup linked list for that type
            Node node = (Node)byType[t.qname()];
            if (node == null) continue;

            // find this thread in the linked list
            Node last = null;
            bool cont = false;
            while (node.service != self)
            {
              last = node;
              node = node.next;
              if (node == null) { cont=true; break; }
            }
            if (cont) continue;

            // update the map or linked list
            if (last == null)
              byType[t.qname()] = node.next;
            else
              last.next = node.next;
          }
        }
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
      }
      return self;
    }

    public static Service start(Service self)
    {
      try
      {
        lock (m_lock)
        {
          // start implies install
          install(self);

          // if already running, short circuit
          State state = (State)byService[self];
          if (state.running) return self;

          // put into the running state
          state.running = true;
        }

        // onStart callback (outside of lock)
        self.onStart();
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
      }
      return self;
    }

    public static Service stop(Service self)
    {
      try
      {
        lock (m_lock)
        {
          // if not running, short circuit
          State state = (State)byService[self];
          if (state == null || !state.running) return self;

          // take out of the running state
          state.running = false;
        }

        // onStop (outside of lock)
        self.onStop();
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
      }
      return self;
    }

    public static void onStart(Service self) {}

    public static void onStop(Service self) {}

  //////////////////////////////////////////////////////////////////////////
  // State/Node
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Value for byService map
    /// </summary>
    internal class State
    {
      public State(Service s) { service = s; }
      public Service service;
      public bool running;
    }

    /// <summary>
    /// Value for byType map
    /// </summary>
    internal class Node
    {
      public Node(Service s) { service = s; }
      public Service service;
      public Node next;
    }
  }
}