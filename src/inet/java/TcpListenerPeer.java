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
      throw IOErr.make(e).val;
    }
  }

  public TcpListenerPeer()
    throws IOException
  {
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public Boolean isBound(TcpListener fan)
  {
    return isBound();
  }

  public Boolean isClosed(TcpListener fan)
  {
    return isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddress localAddress(TcpListener fan)
  {
    if (!isBound()) return null;
    InetAddress addr = getInetAddress();
    if (addr == null) return null;
    return IpAddressPeer.make(addr);
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

  public TcpListener bind(TcpListener fan, IpAddress addr, Long port, Long backlog)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      bind(new InetSocketAddress(javaAddr, javaPort), backlog.intValue());
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public TcpSocket doAccept(TcpListener fan)
  {
    try
    {
      TcpSocket s = TcpSocket.make();
      implAccept(s.peer);
      s.peer.connected(s);
      return s;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Boolean close(TcpListener fan)
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

  public Long getReceiveBufferSize(TcpListener fan)
  {
    try
    {
      return Long.valueOf(getReceiveBufferSize());
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReceiveBufferSize(TcpListener fan, Long v)
  {
    try
    {
      setReceiveBufferSize(v.intValue());
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Boolean getReuseAddress(TcpListener fan)
  {
    try
    {
      return getReuseAddress();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReuseAddress(TcpListener fan, Boolean v)
  {
    try
    {
      setReuseAddress(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Duration getReceiveTimeout(TcpListener fan)
  {
    try
    {
      int timeout = getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReceiveTimeout(TcpListener fan, Duration v)
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
      throw IOErr.make(e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private IpAddress remoteAddr;
  private int remotePort;
  private int inBufSize = 4096;
  private int outBufSize = 4096;
  private SysInStream in;
  private SysOutStream out;

}