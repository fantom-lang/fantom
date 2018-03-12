//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import java.util.Enumeration;
import java.util.Iterator;
import fan.sys.*;

public class IpInterfacePeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static IpInterfacePeer make(IpInterface fan)
  {
    return new IpInterfacePeer();
  }

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  public static List list()
  {
    try
    {
      List acc = new List(type);
      Enumeration e = NetworkInterface.getNetworkInterfaces();
      while (e.hasMoreElements())
        acc.add(make((NetworkInterface)e.nextElement()));
      return acc;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public static IpInterface findByAddr(IpAddr addr) { return findByAddr(addr, true); }
  public static IpInterface findByAddr(IpAddr addr, boolean checked)
  {
    try
    {
      NetworkInterface java = NetworkInterface.getByInetAddress(addr.peer.java);
      if (java != null) return make(java);
      if (checked) throw UnresolvedErr.make("No interface for addr: " + addr);
      return null;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public static IpInterface findByName(String name) { return findByName(name, true); }
  public static IpInterface findByName(String name, boolean checked)
  {
    try
    {
      NetworkInterface java = NetworkInterface.getByName(name);
      if (java != null) return make(java);
      if (checked) throw UnresolvedErr.make("No interface for name: " + name);
      return null;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  static IpInterface make(NetworkInterface java)
  {
    if (java == null) throw new IllegalArgumentException();
    IpInterface fan = IpInterface.make();
    fan.peer.java = java;
    return fan;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public long hash(IpInterface fan)
  {
    return java.hashCode();
  }

  public boolean equals(IpInterface fan, Object obj)
  {
    if (obj instanceof IpInterface)
      return this.java.equals(((IpInterface)obj).peer.java);
    else
      return false;
  }

  public String toStr(IpInterface fan)
  {
    return java.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String name(IpInterface fan)
  {
    String name = java.getName();
    if (name == null) return "?";
    return name;
  }

  public String dis(IpInterface fan)
  {
    return java.getDisplayName();
  }

  public List addrs(IpInterface fan)
  {
    List acc = new List(IpAddrPeer.type);
    Enumeration e = java.getInetAddresses();
    while (e.hasMoreElements())
      acc.add(IpAddrPeer.make((InetAddress)e.nextElement()));
    return acc;
  }

  public List broadcastAddrs(IpInterface fan)
  {
    List acc = new List(IpAddrPeer.type);
    Iterator iter = java.getInterfaceAddresses().iterator();
    while (iter.hasNext())
    {
      InterfaceAddress iface = (InterfaceAddress)iter.next();
      if (iface.getBroadcast() != null)
        acc.add(IpAddrPeer.make(iface.getBroadcast()));
    }
    return acc;
  }

  public boolean isUp(IpInterface fan)
  {
    try
    {
      return java.isUp();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Buf hardwareAddr(IpInterface fan)
  {
    try
    {
      byte[] addr = java.getHardwareAddress();
      if (addr == null) return null;
      return new MemBuf(addr);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long mtu(IpInterface fan)
  {
    try
    {
      return java.getMTU();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean supportsMulticast(IpInterface fan)
  {
    try
    {
      return java.supportsMulticast();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean isPointToPoint(IpInterface fan)
  {
    try
    {
      return java.isPointToPoint();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean isLoopback(IpInterface fan)
  {
    try
    {
      return java.isLoopback();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Type type = Type.find("inet::IpInterface");

  public NetworkInterface java;

}