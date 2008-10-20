//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Nov 07  Andy Frank  Ported to .NET
//

using System;
using System.Net;
using System.Net.Sockets;
using Fan.Sys;

namespace Fan.Inet
{
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
        return make(str, Dns.GetHostEntry(str.val).AddressList[0]);
      }
      catch (SocketException e)
      {
        throw UnknownHostErr.make(Str.make(e.Message)).val;
      }
    }

    public static List makeAll(Str str)
    {
      try
      {
        IPAddress[] addr = Dns.GetHostEntry(str.val).AddressList;
        List list = new List(Fan.Sys.Sys.ObjType, addr.Length); //IpAddress.$Type, addr.length);
        for (int i=0; i<addr.Length; i++)
          list.add(make(str, addr[i]));
        return list;
      }
      catch (SocketException e)
      {
        throw UnknownHostErr.make(Str.make(e.Message)).val;
      }
    }

    public static IpAddress makeBytes(Buf bytes)
    {
      try
      {
        MemBuf mb = bytes as MemBuf;
        IPAddress net = Dns.GetHostEntry(new IPAddress(mb.bytes())).AddressList[0];
        return make(Str.make(net.ToString()), net);
      }
      catch (SocketException e)
      {
        throw ArgErr.make(Str.make(e.Message)).val;
      }
    }

    public static IpAddress local()
    {
      if (m_local == null)
      {
        try
        {
          string hostName = Dns.GetHostName();

          // TODO - not sure the correct behavoir here, but we seem
          // to get IPv6 addresses first, so for now at least, lets
          // attempt to use the IPv4 address

          IPAddress net = null; // Dns.GetHostEntry(hostName).AddressList[0];
          IPAddress[] addr = Dns.GetHostEntry(hostName).AddressList;
          for (int i=0; i<addr.Length; i++)
            if (addr[i].AddressFamily == AddressFamily.InterNetwork)
              net = addr[i];

          m_local = make(Str.make(hostName), net);
        }
        catch (Exception)
        {
          try
          {
            // fallback to explicit loopback
            IPAddress net = new IPAddress(new byte[] {127, 0, 0, 1});
            m_local = make(Str.make(net.ToString()), net);
          }
          catch (Exception ignore)
          {
            // should never happen
            System.Console.WriteLine(ignore);
          }
        }
      }
      return m_local;
    }

    public static IpAddress make(IPAddress net)
    {
      return make(Str.make(net.ToString()), net);
    }

    public static IpAddress make(Str str, IPAddress net)
    {
      IpAddress fan = IpAddress.internalMake();
      fan.m_peer.m_str = str;
      fan.m_peer.m_net = net;
      return fan;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public Long hash(IpAddress fan)
    {
      return Long.valueOf(m_net.GetHashCode());
    }

    public Fan.Sys.Boolean _equals(IpAddress fan, object obj)
    {
      if (obj is IpAddress)
        return Fan.Sys.Boolean.valueOf(this.m_net.Equals(((IpAddress)obj).m_peer.m_net));
      else
        return Fan.Sys.Boolean.False;
    }

    public Str toStr(IpAddress fan)
    {
      return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Fan.Sys.Boolean isIPv4(IpAddress fan)
    {
      return Fan.Sys.Boolean.valueOf(m_net.AddressFamily == AddressFamily.InterNetwork);
    }

    public Fan.Sys.Boolean isIPv6(IpAddress fan)
    {
      return Fan.Sys.Boolean.valueOf(m_net.AddressFamily == AddressFamily.InterNetworkV6);
    }

    public Buf bytes(IpAddress fan)
    {
      return new MemBuf(m_net.GetAddressBytes());
    }

    public Str numeric(IpAddress fan)
    {
      return Str.make(m_net.ToString());
    }

    public Str hostname(IpAddress fan)
    {
      return Str.make(Dns.GetHostEntry(m_net).HostName);
      //return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static IpAddress m_local;

    public Str m_str;
    public IPAddress m_net;

  }
}