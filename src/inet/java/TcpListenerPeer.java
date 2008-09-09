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

  public Bool isBound(TcpListener fan)
  {
    return Bool.make(isBound());
  }

  public Bool isClosed(TcpListener fan)
  {
    return Bool.make(isClosed());
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

  public Int localPort(TcpListener fan)
  {
    if (!isBound()) return null;
    int port = getLocalPort();
    if (port <= 0) return null;
    return Int.make(port);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public TcpListener bind(TcpListener fan, IpAddress addr, Int port, Int backlog)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : (int)port.val;
      bind(new InetSocketAddress(javaAddr, javaPort), (int)backlog.val);
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

  public Bool close(TcpListener fan)
  {
    try
    {
      close();
      return Bool.True;
    }
    catch (Exception e)
    {
      return Bool.False;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public Int getReceiveBufferSize(TcpListener fan)
  {
    try
    {
      return Int.make(getReceiveBufferSize());
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReceiveBufferSize(TcpListener fan, Int v)
  {
    try
    {
      setReceiveBufferSize((int)v.val);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public Bool getReuseAddress(TcpListener fan)
  {
    try
    {
      return Bool.make(getReuseAddress());
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReuseAddress(TcpListener fan, Bool v)
  {
    try
    {
      setReuseAddress(v.val);
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