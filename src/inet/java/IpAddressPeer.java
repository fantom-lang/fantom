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

  public static IpAddress make(Str str)
  {
    try
    {
      return make(str, InetAddress.getByName(str.val));
    }
    catch (UnknownHostException e)
    {
      throw UnknownHostErr.make(Str.make(e.getMessage())).val;
    }
  }

  public static List makeAll(Str str)
  {
    try
    {
      InetAddress[] addr = InetAddress.getAllByName(str.val);
      List list = new List(IpAddress.$Type, addr.length);
      for (int i=0; i<addr.length; ++i)
        list.add(make(str, addr[i]));
      return list;
    }
    catch (UnknownHostException e)
    {
      throw UnknownHostErr.make(Str.make(e.getMessage())).val;
    }
  }

  public static IpAddress makeBytes(Buf bytes)
  {
    try
    {
      MemBuf mb = (MemBuf)bytes;
      InetAddress java = InetAddress.getByAddress(mb.bytes());
      return make(Str.make(java.getHostAddress()), java);
    }
    catch (UnknownHostException e)
    {
      throw ArgErr.make(Str.make(e.getMessage())).val;
    }
  }

  public static IpAddress local()
  {
    if (local == null)
    {
      try
      {
        InetAddress java = InetAddress.getLocalHost();
        local = make(Str.make(java.getHostName()), java);
      }
      catch (Exception e)
      {
        try
        {
          // fallback to explicit loopback
          InetAddress java = InetAddress.getByAddress(new byte[] {127, 0, 0, 1});
          local = make(Str.make(java.getHostAddress()), java);
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
    return make(Str.make(java.getHostAddress()), java);
  }

  public static IpAddress make(Str str, InetAddress java)
  {
    IpAddress fan = IpAddress.internalMake();
    fan.peer.str  = str;
    fan.peer.java = java;
    return fan;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Long hash(IpAddress fan)
  {
    return Long.valueOf(java.hashCode());
  }

  public Boolean _equals(IpAddress fan, Object obj)
  {
    if (obj instanceof IpAddress)
      return this.java.equals(((IpAddress)obj).peer.java);
    else
      return false;
  }

  public Str toStr(IpAddress fan)
  {
    return str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Boolean isIPv4(IpAddress fan)
  {
    return java instanceof Inet4Address;
  }

  public Boolean isIPv6(IpAddress fan)
  {
    return java instanceof Inet6Address;
  }

  public Buf bytes(IpAddress fan)
  {
    return new MemBuf(java.getAddress());
  }

  public Str numeric(IpAddress fan)
  {
    return Str.make(java.getHostAddress());
  }

  public Str hostname(IpAddress fan)
  {
    return Str.make(java.getHostName());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static IpAddress local;

  public Str str;
  public InetAddress java;

}