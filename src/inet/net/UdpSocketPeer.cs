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

    public Bool isBound(UdpSocket fan)
    {
      return Bool.make(m_net.IsBound);
    }

    public Bool isConnected(UdpSocket fan)
    {
      return Bool.make(m_net.Connected);
    }

    public Bool isClosed(UdpSocket fan)
    {
      return Bool.make(m_closed);
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

    public Int localPort(UdpSocket fan)
    {
      if (!m_net.IsBound) return null;
      IPEndPoint pt = m_net.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - default port?
      return Int.make(pt.Port);
    }

    public IpAddress remoteAddress(UdpSocket fan)
    {
      if (!m_net.Connected) return null;
      return m_remoteAddr;
    }

    public Int remotePort(UdpSocket fan)
    {
      if (!m_net.Connected) return null;
      return Int.make(m_remotePort);
    }

  //////////////////////////////////////////////////////////////////////////
  // Communication
  //////////////////////////////////////////////////////////////////////////

    public UdpSocket bind(UdpSocket fan, IpAddress addr, Int port)
    {
      try
      {
        IPAddress netAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_net;
        int netPort = (port == null) ? 0 : (int)port.val;
        m_net.Bind(new IPEndPoint(netAddr, netPort));
        return fan;
      }
      catch (SocketException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public UdpSocket connect(UdpSocket fan, IpAddress addr, Int port)
    {
      try
      {
        m_net.Connect(addr.m_peer.m_net, (int)port.val);
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
      Int port = packet.port();
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
          IPEndPoint endPoint = new IPEndPoint(addr.m_peer.m_net, (int)port.val);
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
      packet.port(Int.make(endPoint.Port));
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

    public Bool close(UdpSocket fan)
    {
      try
      {
        close();
        return Bool.True;
      }
      catch
      {
        return Bool.False;
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

    public Bool getBroadcast(UdpSocket fan)
    {
      return Bool.make(m_net.EnableBroadcast);
    }

    public void setBroadcast(UdpSocket fan, Bool v)
    {
      m_net.EnableBroadcast = v.val;
    }

    public Int getReceiveBufferSize(UdpSocket fan)
    {
      return Int.make(m_net.ReceiveBufferSize);
    }

    public void setReceiveBufferSize(UdpSocket fan, Int v)
    {
      m_net.ReceiveBufferSize = (int)v.val;
    }

    public Int getSendBufferSize(UdpSocket fan)
    {
      return Int.make(m_net.SendBufferSize);
    }

    public void setSendBufferSize(UdpSocket fan, Int v)
    {
      m_net.SendBufferSize = (int)v.val;
    }

    public Bool getReuseAddress(UdpSocket fan)
    {
      return Bool.make(Convert.ToBoolean(
        m_net.GetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress)));
    }

    public void setReuseAddress(UdpSocket fan, Bool v)
    {
      m_net.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, v.val);
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

    public Int getTrafficClass(UdpSocket fan)
    {
      return Int.make(Convert.ToInt32(
        m_net.GetSocketOption(SocketOptionLevel.IP, SocketOptionName.TypeOfService)));
    }

    public void setTrafficClass(UdpSocket fan, Int v)
    {
      m_net.SetSocketOption(SocketOptionLevel.IP, SocketOptionName.TypeOfService, v.val);
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