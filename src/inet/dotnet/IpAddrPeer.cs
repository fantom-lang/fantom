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
  public class IpAddrPeer
  {

  //////////////////////////////////////////////////////////////////////////
  // Peer Factory
  //////////////////////////////////////////////////////////////////////////

    public static IpAddrPeer make(IpAddr fan)
    {
      return new IpAddrPeer();
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static IpAddr make(string str)
    {
      try
      {
        return make(str, Dns.GetHostAddresses(str)[0]);
      }
      catch (SocketException e)
      {
        throw UnknownHostErr.make(e.Message).val;
      }
    }

    public static List makeAll(string str)
    {
      try
      {
        IPAddress[] addr = Dns.GetHostAddresses(str);
        List list = new List(Fan.Sys.Sys.ObjType, addr.Length); //IpAddr.$Type, addr.length);
        for (int i=0; i<addr.Length; i++)
          list.add(make(str, addr[i]));
        return list;
      }
      catch (SocketException e)
      {
        throw UnknownHostErr.make(e.Message).val;
      }
    }

    public static IpAddr makeBytes(Buf bytes)
    {
      try
      {
        MemBuf mb = bytes as MemBuf;
        IPAddress dotnet = new IPAddress(mb.bytes());
        return make(dotnet.ToString(), dotnet);
      }
      catch (SocketException e)
      {
        throw ArgErr.make(e.Message).val;
      }
    }

    public static IpAddr local()
    {
      if (m_local == null)
      {
        try
        {
          string hostName = Dns.GetHostName();

          // TODO - not sure the correct behavoir here, but we seem
          // to get IPv6 addresses first, so for now at least, lets
          // attempt to use the IPv4 address

          IPAddress dotnet = null;
          IPAddress[] addr = Dns.GetHostAddresses(hostName);
          for (int i=0; i<addr.Length; i++)
            if (addr[i].AddressFamily == AddressFamily.InterNetwork)
              dotnet = addr[i];

          m_local = make(hostName, dotnet);
        }
        catch (Exception)
        {
          try
          {
            // fallback to explicit loopback
            IPAddress dotnet = new IPAddress(new byte[] {127, 0, 0, 1});
            m_local = make(dotnet.ToString(), dotnet);
          }
          catch (Exception ignore)
          {
            // should never happen
            Err.dumpStack(ignore);
          }
        }
      }
      return m_local;
    }

    public static IpAddr make(IPAddress dotnet)
    {
      return make(dotnet.ToString(), dotnet);
    }

    public static IpAddr make(string str, IPAddress dotnet)
    {
      IpAddr fan = IpAddr.internalMake();
      fan.m_peer.m_str = str;
      fan.m_peer.m_dotnet = dotnet;
      return fan;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public long hash(IpAddr fan)
    {
      return m_dotnet.GetHashCode();
    }

    public bool Equals(IpAddr fan, object obj)
    {
      if (obj is IpAddr)
        return this.m_dotnet.Equals(((IpAddr)obj).m_peer.m_dotnet);
      else
        return false;
    }

    public string toStr(IpAddr fan)
    {
      return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public bool isIPv4(IpAddr fan)
    {
      return m_dotnet.AddressFamily == AddressFamily.InterNetwork;
    }

    public bool isIPv6(IpAddr fan)
    {
      return m_dotnet.AddressFamily == AddressFamily.InterNetworkV6;
    }

    public Buf bytes(IpAddr fan)
    {
      return new MemBuf(m_dotnet.GetAddressBytes());
    }

    public string numeric(IpAddr fan)
    {
      return m_dotnet.ToString();
    }

    public string hostname(IpAddr fan)
    {
      return Dns.GetHostEntry(m_dotnet).HostName;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static IpAddr m_local;

    public string m_str;
    public IPAddress m_dotnet;

  }
}