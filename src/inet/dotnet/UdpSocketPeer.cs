//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jan 08  Andy Frank  Ported to .NET
//

using System;
using System.Net;
using System.Net.Sockets;
using Fan.Sys;

namespace Fan.Inet
{
  public class UdpSocketPeer
  {

  //////////////////////////////////////////////////////////////////////////
  // Peer Factory
  //////////////////////////////////////////////////////////////////////////

    public static UdpSocketPeer make(UdpSocket fan)
    {
      return new UdpSocketPeer();
    }

    private Socket createSocket()
    {
      // TODO - hardcoded to IPv4!
      Socket s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
      s.EnableBroadcast   = m_enableBroadcast;
      s.ReceiveBufferSize = (int)m_receiveBufferSize;
      s.SendBufferSize    = (int)m_sendBufferSize;
      s.ReceiveTimeout    = m_receiveTimeout;
      s.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, m_reuseAddr);
      s.SetSocketOption(SocketOptionLevel.IP, SocketOptionName.TypeOfService, (int)m_trafficClass);
      return s;
    }

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    public bool isBound(UdpSocket fan)
    {
      return (m_dotnet == null) ? false : m_dotnet.IsBound;
    }

    public bool isConnected(UdpSocket fan)
    {
      return (m_dotnet == null) ? false : m_dotnet.Connected;
    }

    public bool isClosed(UdpSocket fan)
    {
      return m_closed;
    }

  //////////////////////////////////////////////////////////////////////////
  // End Points
  //////////////////////////////////////////////////////////////////////////

    public IpAddr localAddr(UdpSocket fan)
    {
      if (!isBound(fan)) return null;
      IPEndPoint pt = m_dotnet.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      return IpAddrPeer.make(pt.Address);
    }

    public Long localPort(UdpSocket fan)
    {
      if (!isBound(fan)) return null;
      IPEndPoint pt = m_dotnet.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - default port?
      return Long.valueOf(pt.Port);
    }

    public IpAddr remoteAddr(UdpSocket fan)
    {
      if (!isConnected(fan)) return null;
      return m_remoteAddr;
    }

    public Long remotePort(UdpSocket fan)
    {
      if (!isConnected(fan)) return null;
      return Long.valueOf(m_remotePort);
    }

  //////////////////////////////////////////////////////////////////////////
  // Communication
  //////////////////////////////////////////////////////////////////////////

    public UdpSocket bind(UdpSocket fan, IpAddr addr, Long port)
    {
      try
      {
        if (m_dotnet == null) m_dotnet = createSocket();
        IPAddress dotnetAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_dotnet;
        int dotnetPort = (port == null) ? 0 : port.intValue();
        m_dotnet.Bind(new IPEndPoint(dotnetAddr, dotnetPort));
        return fan;
      }
      catch (SocketException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public UdpSocket connect(UdpSocket fan, IpAddr addr, long port)
    {
      try
      {
        if (m_dotnet == null) m_dotnet = createSocket();
        m_dotnet.Connect(addr.m_peer.m_dotnet, (int)port);
        IPEndPoint endPoint = m_dotnet.RemoteEndPoint as IPEndPoint;
        m_remoteAddr = IpAddrPeer.make(endPoint.Address);
        m_remotePort = endPoint.Port;
        return fan;
      }
      catch (SocketException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public void send(UdpSocket fan, UdpPacket packet)
    {
      // map buf bytes to packet
      MemBuf data = (MemBuf)packet.data();
      byte[] buf = data.m_buf;
      int off = data.m_pos;
      int len = data.m_size - off;

      // map address, port
      IpAddr addr = packet.addr();
      Long port = packet.port();
      if (isConnected(fan))
      {
        if (addr != null || port != null)
          throw ArgErr.make("Address and port must be null to send while connected").val;

        try
        {
          m_dotnet.Send(buf, off, len, SocketFlags.None);
        }
        catch (SocketException e)
        {
          throw IOErr.make(e).val;
        }
      }
      else
      {
        if (addr == null || port == null)
          throw ArgErr.make("Address or port is null").val;

        try
        {
          if (m_dotnet == null) m_dotnet = createSocket();
          IPEndPoint endPoint = new IPEndPoint(addr.m_peer.m_dotnet, port.intValue());
          m_dotnet.SendTo(buf, off, len, SocketFlags.None, endPoint);
        }
        catch (SocketException e)
        {
          throw IOErr.make(e).val;
        }
      }

      // lastly drain buf
      data.m_pos += len;
    }

    public UdpPacket receive(UdpSocket fan, UdpPacket packet)
    {
      // create packet if null
      if (packet == null)
        packet = UdpPacket.make(null, null, new MemBuf(1024));

      // map buf bytes to packet
      MemBuf data = (MemBuf)packet.data();
      byte[] buf = data.m_buf;
      int off = data.m_pos;
      int len = buf.Length - off;
      int recv = 0;
      EndPoint sender = new IPEndPoint(IPAddress.Any, 0);

      // receive
      if (isConnected(fan))
      {
        try
        {
          recv = m_dotnet.Receive(buf, off, len, SocketFlags.None);
          sender = m_dotnet.RemoteEndPoint;
        }
        catch (SocketException e)
        {
          // .NET will truncate contents correctly, but still throws a
          // SocketException, so catch that specific case and allow it
          if (e.Message.StartsWith("A message sent on a datagram socket was larger"))
          {
            recv = len;
            sender = m_dotnet.RemoteEndPoint;
          }
          else
          {
            throw IOErr.make(e).val;
          }
        }
      }
      else
      {
        try
        {
          if (m_dotnet == null) m_dotnet = createSocket();
          recv = m_dotnet.ReceiveFrom(buf, off, len, SocketFlags.None, ref sender);
        }
        catch (SocketException e)
        {
          // .NET will truncate contents correctly, but still throws a
          // SocketException, so catch that specific case and allow it
          if (e.Message.StartsWith("A message sent on a datagram socket was larger"))
            recv = len;
          else
            throw IOErr.make(e).val;
        }
      }

      // update packet with received message
      IPEndPoint endPoint = sender as IPEndPoint;
      packet.addr(IpAddrPeer.make(endPoint.Address));
      packet.port(Long.valueOf(endPoint.Port));
      data.m_pos  += recv;
      data.m_size += recv;

      return packet;
    }

    public UdpSocket disconnect(UdpSocket fan)
    {
      //m_dotnet.Shutdown(SocketShutdown.Both);
      //m_dotnet.Disconnect(true);
      m_dotnet.Close();
      m_dotnet = null;

      m_remoteAddr = null;
      m_remotePort = -1;
      return fan;
    }

    public bool close(UdpSocket fan)
    {
      try
      {
        close();
        return true;
      }
      catch
      {
        return false;
      }
    }

    public void close()
    {
      m_dotnet.Close();
      m_dotnet = null;
      m_closed = true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Socket Options
  //////////////////////////////////////////////////////////////////////////

    public SocketOptions options(UdpSocket fan)
    {
      if (m_options == null) m_options = SocketOptions.make(fan);
      return m_options;
    }

    public bool getBroadcast(UdpSocket fan) { return m_enableBroadcast; }
    public void setBroadcast(UdpSocket fan, bool v) { m_enableBroadcast = v; }

    public long getReceiveBufferSize(UdpSocket fan) { return m_receiveBufferSize; }
    public void setReceiveBufferSize(UdpSocket fan, long v) { m_receiveBufferSize = v; }

    public long getSendBufferSize(UdpSocket fan) { return m_sendBufferSize; }
    public void setSendBufferSize(UdpSocket fan, long v) { m_sendBufferSize = v; }

    public bool getReuseAddr(UdpSocket fan) { return m_reuseAddr; }
    public void setReuseAddr(UdpSocket fan, bool v) { m_reuseAddr = v; }

    public Duration getReceiveTimeout(UdpSocket fan)
    {
      if (m_receiveTimeout <= 0) return null;
      return Duration.makeMillis(m_receiveTimeout);
    }

    public void setReceiveTimeout(UdpSocket fan, Duration v)
    {
      m_receiveTimeout = (v == null) ? 0 : (int)v.millis();
    }

    public long getTrafficClass(UdpSocket fan) { return m_trafficClass; }
    public void setTrafficClass(UdpSocket fan, long v) { m_trafficClass = v; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Socket m_dotnet;

    private IpAddr m_remoteAddr;
    private int m_remotePort;
    private SocketOptions m_options;
    private bool m_closed;

    private bool m_enableBroadcast   = false;
    private long m_receiveBufferSize = 8192;
    private long m_sendBufferSize    = 8192;
    private bool m_reuseAddr         = false;
    private int m_receiveTimeout     = 0;
    private long m_trafficClass      = 0;

  }
}