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

  private static Object lock = new Object();
  private static HashMap map = new HashMap();  // Type:Node
  private static List list = new List(Sys.ServiceType);

  public static List list()
  {
    synchronized (lock)
    {
      return list.dup().ro();
    }
  }

  public static Service find(Type t) { return find(t, true); }
  public static Service find(Type t, boolean checked)
  {
    String qname = t.qname();
    synchronized (lock)
    {
      Node node = (Node)map.get(qname);
      if (node != null) return node.service;
      if (checked) throw UnknownServiceErr.make(qname).val;
      return null;
    }
  }

  public static List findAll(Type t)
  {
    String qname = t.qname();
    List list = new List(Sys.ServiceType);
    synchronized (lock)
    {
      Node node = (Node)map.get(qname);
      while (node != null)
      {
        list.add(node.service);
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
      synchronized (lock)
      {
        // if already installed, short circuit
        if (list.containsSame(self)) return self;

        // add to list
        list.add(self);

        // add to map for each type service implements
        for (int i=0; i<types.sz(); ++i)
        {
          Type t = (Type)types.get(i);
          if (!isServiceType(t)) continue;
          Node node = new Node();
          node.service = self;
          Node x = (Node)map.get(t.qname());
          if (x == null) map.put(t.qname(), node);
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
      List types = FanObj.type(self).inheritance();
      synchronized (lock)
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
          Node node = (Node)map.get(t.qname());
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
            map.put(t.qname(), node.next);
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

  static boolean isServiceType(Type t)
  {
    return t != Sys.ObjType && t != Sys.ThreadType && t.isPublic();
  }

  static class Node
  {
    Service service;
    Node next;
  }

}