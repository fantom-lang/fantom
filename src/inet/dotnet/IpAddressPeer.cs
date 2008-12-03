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

    public static IpAddress make(string str)
    {
      try
      {
        return make(str, Dns.GetHostEntry(str).AddressList[0]);
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
        IPAddress[] addr = Dns.GetHostEntry(str).AddressList;
        List list = new List(Fan.Sys.Sys.ObjType, addr.Length); //IpAddress.$Type, addr.length);
        for (int i=0; i<addr.Length; i++)
          list.add(make(str, addr[i]));
        return list;
      }
      catch (SocketException e)
      {
        throw UnknownHostErr.make(e.Message).val;
      }
    }

    public static IpAddress makeBytes(Buf bytes)
    {
      try
      {
        MemBuf mb = bytes as MemBuf;
        IPAddress dotnet = Dns.GetHostEntry(new IPAddress(mb.bytes())).AddressList[0];
        return make(dotnet.ToString(), dotnet);
      }
      catch (SocketException e)
      {
        throw ArgErr.make(e.Message).val;
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

          IPAddress dotnet = null; // Dns.GetHostEntry(hostName).AddressList[0];
          IPAddress[] addr = Dns.GetHostEntry(hostName).AddressList;
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
            System.Console.WriteLine(ignore);
          }
        }
      }
      return m_local;
    }

    public static IpAddress make(IPAddress dotnet)
    {
      return make(dotnet.ToString(), dotnet);
    }

    public static IpAddress make(string str, IPAddress dotnet)
    {
      IpAddress fan = IpAddress.internalMake();
      fan.m_peer.m_str = str;
      fan.m_peer.m_dotnet = dotnet;
      return fan;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public long hash(IpAddress fan)
    {
      return m_dotnet.GetHashCode();
    }

    public bool Equals(IpAddress fan, object obj)
    {
      if (obj is IpAddress)
        return this.m_dotnet.Equals(((IpAddress)obj).m_peer.m_dotnet);
      else
        return false;
    }

    public string toStr(IpAddress fan)
    {
      return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public bool isIPv4(IpAddress fan)
    {
      return m_dotnet.AddressFamily == AddressFamily.InterNetwork;
    }

    public bool isIPv6(IpAddress fan)
    {
      return m_dotnet.AddressFamily == AddressFamily.InterNetworkV6;
    }

    public Buf bytes(IpAddress fan)
    {
      return new MemBuf(m_dotnet.GetAddressBytes());
    }

    public string numeric(IpAddress fan)
    {
      return m_dotnet.ToString();
    }

    public string hostname(IpAddress fan)
    {
      return Dns.GetHostEntry(m_dotnet).HostName;
      //return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static IpAddress m_local;

    public string m_str;
    public IPAddress m_dotnet;

  }
}