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

    // TODO - hardcoded to IPv4!
    public UdpSocketPeer()
      : this(new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp))
    {
    }

    public UdpSocketPeer(Socket socket)
    {
      this.m_net = socket;
    }

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    public bool isBound(UdpSocket fan)
    {
      return m_net.IsBound;
    }

    public bool isConnected(UdpSocket fan)
    {
      return m_net.Connected;
    }

    public bool isClosed(UdpSocket fan)
    {
      return m_closed;
    }

  //////////////////////////////////////////////////////////////////////////
  // End Points
  //////////////////////////////////////////////////////////////////////////

    public IpAddress localAddress(UdpSocket fan)
    {
      if (!m_net.IsBound) return null;
      IPEndPoint pt = m_net.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      return IpAddressPeer.make(pt.Address);
    }

    public Long localPort(UdpSocket fan)
    {
      if (!m_net.IsBound) return null;
      IPEndPoint pt = m_net.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - default port?
      return Long.valueOf(pt.Port);
    }

    public IpAddress remoteAddress(UdpSocket fan)
    {
      if (!m_net.Connected) return null;
      return m_remoteAddr;
    }

    public Long remotePort(UdpSocket fan)
    {
      if (!m_net.Connected) return null;
      return Long.valueOf(m_remotePort);
    }

  //////////////////////////////////////////////////////////////////////////
  // Communication
  //////////////////////////////////////////////////////////////////////////

    public UdpSocket bind(UdpSocket fan, IpAddress addr, Long port)
    {
      try
      {
        IPAddress netAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_net;
        int netPort = (port == null) ? 0 : port.intValue();
        m_net.Bind(new IPEndPoint(netAddr, netPort));
        return fan;
      }
      catch (SocketException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public UdpSocket connect(UdpSocket fan, IpAddress addr, long port)
    {
      try
      {
        m_net.Connect(addr.m_peer.m_net, (int)port);
        IPEndPoint endPoint = m_net.RemoteEndPoint as IPEndPoint;
        m_remoteAddr = IpAddressPeer.make(endPoint.Address);
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
      IpAddress addr = packet.address();
      Long port = packet.port();
      if (m_net.Connected)
      {
        if (addr != null || port != null)
          throw ArgErr.make("Address and port must be null to send while connected").val;

        try
        {
          m_net.Send(buf, off, len, SocketFlags.None);
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
          IPEndPoint endPoint = new IPEndPoint(addr.m_peer.m_net, port.intValue());
          m_net.SendTo(buf, off, len, SocketFlags.None, endPoint);
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
      if (m_net.Connected)
      {
        try
        {
          recv = m_net.Receive(buf, off, len, SocketFlags.None);
          sender = m_net.RemoteEndPoint;
        }
        catch (SocketException e)
        {
          throw IOErr.make(e).val;
        }
      }
      else
      {
        try
        {
          recv = m_net.ReceiveFrom(buf, off, len, SocketFlags.None, ref sender);
        }
        catch (SocketException e)
        {
          throw IOErr.make(e).val;
        }
      }

      // update packet with received message
      IPEndPoint endPoint = sender as IPEndPoint;
      packet.address(IpAddressPeer.make(endPoint.Address));
      packet.port(Long.valueOf(endPoint.Port));
      data.m_pos  += recv;
      data.m_size += recv;

      return packet;
    }

    public UdpSocket disconnect(UdpSocket fan)
    {
      //m_net.Shutdown(SocketShutdown.Both);
      //m_net.Disconnect(true);
      m_net.Close();

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
      m_net.Close();
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

    public bool getBroadcast(UdpSocket fan)
    {
      return m_net.EnableBroadcast;
    }

    public void setBroadcast(UdpSocket fan, bool v)
    {
      m_net.EnableBroadcast = v;
    }

    public long getReceiveBufferSize(UdpSocket fan)
    {
      return m_net.ReceiveBufferSize;
    }

    public void setReceiveBufferSize(UdpSocket fan, long v)
    {
      m_net.ReceiveBufferSize = (int)v;
    }

    public long getSendBufferSize(UdpSocket fan)
    {
      return m_net.SendBufferSize;
    }

    public void setSendBufferSize(UdpSocket fan, long v)
    {
      m_net.SendBufferSize = (int)v;
    }

    public bool getReuseAddress(UdpSocket fan)
    {
      return Convert.ToBoolean(m_net.GetSocketOption(
       SocketOptionLevel.Socket, SocketOptionName.ReuseAddress));
    }

    public void setReuseAddress(UdpSocket fan, bool v)
    {
      m_net.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, v);
    }

    public Duration getReceiveTimeout(UdpSocket fan)
    {
      if (m_net.ReceiveTimeout <= 0) return null;
      return Duration.makeMillis(m_net.ReceiveTimeout);
    }

    public void setReceiveTimeout(UdpSocket fan, Duration v)
    {
      if (v == null)
        m_net.ReceiveTimeout = 0;
      else
        m_net.ReceiveTimeout = (int)(v.millis());
    }

    public long getTrafficClass(UdpSocket fan)
    {
      return Convert.ToInt32(m_net.GetSocketOption(
        SocketOptionLevel.IP,SocketOptionName.TypeOfService));
    }

    public void setTrafficClass(UdpSocket fan, long v)
    {
      m_net.SetSocketOption(SocketOptionLevel.IP, SocketOptionName.TypeOfService, v);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Socket m_net;

    private IpAddress m_remoteAddr;
    private int m_remotePort;
    private SocketOptions m_options;
    private bool m_closed;

  }
}