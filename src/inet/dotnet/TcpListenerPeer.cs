//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Nov 07  Andy Frank  Ported to .NET
//

using System;
using System.Net;
using System.Net.Sockets;
using Fan.Sys;

namespace Fan.Inet
{

  public class TcpListenerPeer
  {

  //////////////////////////////////////////////////////////////////////////
  // Peer Factory
  //////////////////////////////////////////////////////////////////////////

    public static TcpListenerPeer make(TcpListener fan)
    {
      return new TcpListenerPeer();
    }

    public TcpListenerPeer() {}

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    public bool isBound(TcpListener fan)
    {
      return m_bound;
    }

    public bool isClosed(TcpListener fan)
    {
      return m_closed;
    }

  //////////////////////////////////////////////////////////////////////////
  // End Points
  //////////////////////////////////////////////////////////////////////////

    public IpAddr localAddr(TcpListener fan)
    {
      if (!m_bound) return null;
      IPEndPoint pt = m_dotnet.LocalEndpoint as IPEndPoint;
      if (pt == null) return null;
      return IpAddrPeer.make(pt.Address);
    }

    public Long localPort(TcpListener fan)
    {
      if (!m_bound) return null;
      IPEndPoint pt = m_dotnet.LocalEndpoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - null for default port?
      return Long.valueOf(pt.Port);
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public TcpListener bind(TcpListener fan, IpAddr addr, Long port, long backlog)
    {
      IPAddress dotnetAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_dotnet;
      int dotnetPort = (port == null) ? 0 : port.intValue();
      m_dotnet = new System.Net.Sockets.TcpListener(dotnetAddr, dotnetPort);
      m_dotnet.Server.ReceiveBufferSize = (int)m_receiveBufferSize;
      m_dotnet.Server.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, m_reuseAddr);
      m_dotnet.Start((int)backlog);
      m_bound = true;
      return fan;
    }

    public TcpSocket doAccept(TcpListener fan)
    {
      TcpSocket s = TcpSocket.make();
      if (m_timeout > 0)
      {
        IAsyncResult result = m_dotnet.BeginAcceptSocket(null, null);
        bool success = result.AsyncWaitHandle.WaitOne(m_timeout, true);
        if (!success) throw new System.IO.IOException("Connection timed out.");
        s.m_peer = new TcpSocketPeer(m_dotnet.EndAcceptSocket(result));
      }
      else
      {
        s.m_peer = new TcpSocketPeer(m_dotnet.AcceptSocket());
      }
      s.m_peer.connected(s);
      return s;
    }

    public bool close(TcpListener fan)
    {
      try
      {
        m_dotnet.Stop();
        m_closed = true;
        return true;
      }
      catch (Exception)
      {
        return false;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Socket Options
  //////////////////////////////////////////////////////////////////////////

    public long getReceiveBufferSize(TcpListener fan) { return m_receiveBufferSize; }
    public void setReceiveBufferSize(TcpListener fan, long v) { m_receiveBufferSize = v; }

    public bool getReuseAddr(TcpListener fan) { return m_reuseAddr; }
    public void setReuseAddr(TcpListener fan, bool v) { m_reuseAddr = v; }

    public Duration getReceiveTimeout(TcpListener fan)
    {
      if (m_timeout <= 0) return null;
      return Duration.makeMillis(m_timeout);
    }

    public void setReceiveTimeout(TcpListener fan, Duration v)
    {
      m_timeout = (v == null) ? 0 : (int)(v.millis());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private System.Net.Sockets.TcpListener m_dotnet;
    private bool m_bound  = false;
    private bool m_closed = false;
    private long m_receiveBufferSize = 8192;
    private bool m_reuseAddr = false;
    private int m_timeout = 0;            // accept timeout in millis

  }
}