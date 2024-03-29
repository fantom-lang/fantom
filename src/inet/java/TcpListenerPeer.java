//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 07  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import java.util.*;
import java.security.*;
import javax.net.ssl.*;
import fan.sys.*;

public class TcpListenerPeer
  extends ServerSocket
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static TcpListenerPeer make(TcpListener fan)
  {
    try
    {
      return new TcpListenerPeer();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpListener init(TcpListener fan, SocketConfig config)
  {
    this.config = config;
    setReceiveBufferSize(fan, config.receiveBufferSize);
    setReuseAddr(fan, config.reuseAddr);
    setAcceptTimeout(fan, config.acceptTimeout);
    return fan;
  }

  public TcpListenerPeer()
    throws IOException
  {
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public SocketConfig config(TcpListener self)
  {
    return this.config;
  }

  public boolean isBound(TcpListener fan)
  {
    return isBound();
  }

  public boolean isClosed(TcpListener fan)
  {
    return isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddr localAddr(TcpListener fan)
  {
    if (!isBound()) return null;
    InetAddress addr = getInetAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(TcpListener fan)
  {
    if (!isBound()) return null;
    int port = getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public TcpListener bind(TcpListener fan, IpAddr addr, Long port, long backlog)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      bind(new InetSocketAddress(javaAddr, javaPort), (int)backlog);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpSocket doAccept(TcpListener fan)
  {
    try
    {
      TcpSocket s = TcpSocketPeer.makeNative(new Socket(), this.config, true);
      implAccept(s.peer.socket);
      s.peer.connected(s);
      return s;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean close(TcpListener fan)
  {
    try
    {
      close();
      return true;
    }
    catch (Exception e)
    {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public long getReceiveBufferSize(TcpListener fan)
  {
    try
    {
      return getReceiveBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReceiveBufferSize(TcpListener fan, long v)
  {
    try
    {
      setReceiveBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean getReuseAddr(TcpListener fan)
  {
    try
    {
      return getReuseAddress();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReuseAddr(TcpListener fan, boolean v)
  {
    try
    {
      setReuseAddress(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Duration getAcceptTimeout(TcpListener fan)
  {
    try
    {
      int timeout = getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setAcceptTimeout(TcpListener fan, Duration v)
  {
    try
    {
      if (v == null)
        setSoTimeout(0);
      else
        setSoTimeout((int)(v.millis()));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private SocketConfig config;
  private int inBufSize = 4096;
  private int outBufSize = 4096;
  private SysInStream in;
  private SysOutStream out;

}
