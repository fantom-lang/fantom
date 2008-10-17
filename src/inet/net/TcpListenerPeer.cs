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

    public Fan.Sys.Boolean isBound(TcpListener fan)
    {
      return Fan.Sys.Boolean.valueOf(m_bound);
    }

    public Fan.Sys.Boolean isClosed(TcpListener fan)
    {
      return Fan.Sys.Boolean.valueOf(m_closed);
    }

  //////////////////////////////////////////////////////////////////////////
  // End Points
  //////////////////////////////////////////////////////////////////////////

    public IpAddress localAddress(TcpListener fan)
    {
      if (!m_bound) return null;
      IPEndPoint pt = m_net.LocalEndpoint as IPEndPoint;
      if (pt == null) return null;
      return IpAddressPeer.make(pt.Address);
    }

    public Int localPort(TcpListener fan)
    {
      if (!m_bound) return null;
      IPEndPoint pt = m_net.LocalEndpoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - null for default port?
      return Int.make(pt.Port);
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public TcpListener bind(TcpListener fan, IpAddress addr, Int port, Int backlog)
    {
      IPAddress netAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_net;
      int netPort = (port == null) ? 0 : (int)port.val;
      m_net = new System.Net.Sockets.TcpListener(netAddr, netPort);
      m_net.Start((int)backlog.val);
      m_bound = true;
      return fan;
    }

    public TcpSocket doAccept(TcpListener fan)
    {
      TcpSocket s = TcpSocket.make();
      if (m_timeout > 0)
      {
        IAsyncResult result = m_net.BeginAcceptSocket(null, null);
        bool success = result.AsyncWaitHandle.WaitOne(m_timeout, true);
        if (!success) throw new System.IO.IOException("Connection timed out.");
        s.m_peer = new TcpSocketPeer(m_net.EndAcceptSocket(result));
      }
      else
      {
        s.m_peer = new TcpSocketPeer(m_net.AcceptSocket());
      }
      s.m_peer.connected(s);
      return s;
    }

    public Fan.Sys.Boolean close(TcpListener fan)
    {
      try
      {
        m_net.Stop();
        m_closed = true;
        return Fan.Sys.Boolean.True;
      }
      catch (Exception)
      {
        return Fan.Sys.Boolean.False;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Socket Options
  //////////////////////////////////////////////////////////////////////////

    public Int getReceiveBufferSize(TcpListener fan)
    {
      return Int.make(m_net.Server.ReceiveBufferSize);
    }

    public void setReceiveBufferSize(TcpListener fan, Int v)
    {
      m_net.Server.ReceiveBufferSize = (int)v.val;
    }

    public Fan.Sys.Boolean getReuseAddress(TcpListener fan)
    {
      return Fan.Sys.Boolean.valueOf(Convert.ToBoolean(
        m_net.Server.GetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress)));
    }

    public void setReuseAddress(TcpListener fan, Fan.Sys.Boolean v)
    {
      m_net.Server.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, v.booleanValue());
    }

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

    private System.Net.Sockets.TcpListener m_net;
    private bool m_bound  = false;
    private bool m_closed = false;
    private int m_timeout = 0;       // accept timeout in millis

  }
}