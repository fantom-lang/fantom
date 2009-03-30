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

    private static object m_lock = new object();
    private static Hashtable m_map = new Hashtable();  // Type:Node
    private static List m_list = new List(Sys.ServiceType);

    public static List list()
    {
      lock (m_lock)
      {
        return m_list.dup().ro();
      }
    }

    public static Service find(Type t) { return find(t, true); }
    public static Service find(Type t, bool check)
    {
      string qname = t.qname();
      lock (m_lock)
      {
        Node node = (Node)m_map[qname];
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
        Node node = (Node)m_map[qname];
        while (node != null)
        {
          m_list.add(node.service);
          node = node.next;
        }
      }
      return list.ro();
    }

    public static Service install(Service self)
    {
      try
      {
        List types = FanObj.type(self).inheritance();
        lock (m_lock)
        {
          // if already installed, short circuit
          if (m_list.containsSame(self)) return self;

          // add to list
          m_list.add(self);

          // add to map for each type service implements
          for (int i=0; i<types.sz(); ++i)
          {
            Type t = (Type)types.get(i);
            if (!isServiceType(t)) continue;
            Node node = new Node();
            node.service = self;
            Node x = (Node)m_map[t.qname()];
            if (x == null) m_map[t.qname()] = node;
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
throw new System.Exception("Service_.uninstall() not implemented");
      /*
      try
      {
        List types = FanObj.type(self).inheritance();
        lock (m_lock)
        {
          // remove from list, it not installed short circuit
          if (list.removeSame(self) == null) return self;

          // remove from map for each type implemented by service
          nextType: for (int i=0; i<types.sz(); ++i)
          {
            // get next type in inheritance and check if service type
            Type t = (Type)types.get(i);
            if (!isServiceType(t)) continue nextType;

            // lookup linked list for that type
            Node node = (Node)m_map[t.qname()];
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
              map[t.qname()] = node.next;
            else
              last.next = node.next;
          }
        }
      }
      catch (Throwable e)
      {
        Err.dumpStack(e);
      }
      return self;
      */
    }

    internal static bool isServiceType(Type t)
    {
      return t != Sys.ObjType && t != Sys.ThreadType && t.isPublic();
    }

    internal class Node
    {
      internal Service service;
      internal Node next;
    }

  }
}