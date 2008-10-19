//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import fan.sys.*;

public class IpAddressPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static IpAddressPeer make(IpAddress fan)
  {
    return new IpAddressPeer();
  }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static IpAddress make(String str)
  {
    try
    {
      return make(str, InetAddress.getByName(str));
    }
    catch (UnknownHostException e)
    {
      throw UnknownHostErr.make(e.getMessage()).val;
    }
  }

  public static List makeAll(String str)
  {
    try
    {
      InetAddress[] addr = InetAddress.getAllByName(str);
      List list = new List(IpAddress.$Type, addr.length);
      for (int i=0; i<addr.length; ++i)
        list.add(make(str, addr[i]));
      return list;
    }
    catch (UnknownHostException e)
    {
      throw UnknownHostErr.make(e.getMessage()).val;
    }
  }

  public static IpAddress makeBytes(Buf bytes)
  {
    try
    {
      MemBuf mb = (MemBuf)bytes;
      InetAddress java = InetAddress.getByAddress(mb.bytes());
      return make(java.getHostAddress(), java);
    }
    catch (UnknownHostException e)
    {
      throw ArgErr.make(e.getMessage()).val;
    }
  }

  public static IpAddress local()
  {
    if (local == null)
    {
      try
      {
        InetAddress java = InetAddress.getLocalHost();
        local = make(java.getHostName(), java);
      }
      catch (Exception e)
      {
        try
        {
          // fallback to explicit loopback
          InetAddress java = InetAddress.getByAddress(new byte[] {127, 0, 0, 1});
          local = make(java.getHostAddress(), java);
        }
        catch (Exception ignore)
        {
          // should never happen
          ignore.printStackTrace();
        }
      }
    }
    return local;
  }

  public static IpAddress make(InetAddress java)
  {
    return make(java.getHostAddress(), java);
  }

  public static IpAddress make(String str, InetAddress java)
  {
    IpAddress fan = IpAddress.internalMake();
    fan.peer.str  = str;
    fan.peer.java = java;
    return fan;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public long hash(IpAddress fan)
  {
    return java.hashCode();
  }

  public boolean equals(IpAddress fan, Object obj)
  {
    if (obj instanceof IpAddress)
      return this.java.equals(((IpAddress)obj).peer.java);
    else
      return false;
  }

  public String toStr(IpAddress fan)
  {
    return str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public boolean isIPv4(IpAddress fan)
  {
    return java instanceof Inet4Address;
  }

  public boolean isIPv6(IpAddress fan)
  {
    return java instanceof Inet6Address;
  }

  public Buf bytes(IpAddress fan)
  {
    return new MemBuf(java.getAddress());
  }

  public String numeric(IpAddress fan)
  {
    return java.getHostAddress();
  }

  public String hostname(IpAddress fan)
  {
    return java.getHostName();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static IpAddress local;

  public String str;
  public InetAddress java;

}