//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import fan.sys.*;
import javax.net.ssl.*;

public class TcpSocketPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static TcpSocketPeer make(TcpSocket fan)
  {
    return new TcpSocketPeer(new Socket());
  }

  public static TcpSocket makeTls(TcpSocket upgrade)
  {
    try
    {
      // get SSL factory because Java loves factories!
      SSLSocketFactory factory = (SSLSocketFactory)SSLSocketFactory.getDefault();

      // create new SSL socket
      SSLSocket socket;
      if (upgrade == null)
      {
        socket = (SSLSocket)factory.createSocket();
      }

      // upgrade an existing socket
      else
      {
        socket = (SSLSocket)factory.createSocket(
                   upgrade.peer.socket,
                   upgrade.peer.socket.getInetAddress().getHostAddress(),
                   upgrade.peer.socket.getPort(),
                   false);
        socket.setUseClientMode(true);
        socket.startHandshake();
      }

      // create the new TcpSocket instance
      TcpSocket self = new TcpSocket();
      self.peer = new TcpSocketPeer(socket);

      // if upgrade, then initialize socket as already connected
      if (upgrade != null) self.peer.connected(self);

      return self;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpSocketPeer(Socket socket)
  {
    this.socket = socket;

    // turn off Nagle's algorithm since we should
    // always be doing buffering in the virtual machine
    try { socket.setTcpNoDelay(true); } catch (Exception e) {}
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public boolean isBound(TcpSocket fan)
  {
    return socket.isBound();
  }

  public boolean isConnected(TcpSocket fan)
  {
    return socket.isConnected();
  }

  public boolean isClosed(TcpSocket fan)
  {
    return socket.isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddr localAddr(TcpSocket fan)
  {
    if (!socket.isBound()) return null;
    InetAddress addr = socket.getLocalAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(TcpSocket fan)
  {
    if (!socket.isBound()) return null;
    int port = socket.getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

  public IpAddr remoteAddr(TcpSocket fan)
  {
    if (!socket.isConnected()) return null;
    return remoteAddr;
  }

  public Long remotePort(TcpSocket fan)
  {
    if (!socket.isConnected()) return null;
    return Long.valueOf(remotePort);
  }

//////////////////////////////////////////////////////////////////////////
// Communication
//////////////////////////////////////////////////////////////////////////

  public TcpSocket bind(TcpSocket fan, IpAddr addr, Long port)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      socket.bind(new InetSocketAddress(javaAddr, javaPort));
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpSocket connect(TcpSocket fan, IpAddr addr, long port, Duration timeout)
  {
    try
    {
      // connect
      int javaTimeout = (timeout == null) ? 0 : (int)timeout.millis();
      socket.connect(new InetSocketAddress(addr.peer.java, (int)port), javaTimeout);
      connected(fan);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  void connected(TcpSocket fan)
    throws IOException
  {
    InetSocketAddress sockAddr = (InetSocketAddress)socket.getRemoteSocketAddress();
    this.remoteAddr = IpAddrPeer.make(sockAddr.getAddress());
    this.remotePort = sockAddr.getPort();
    this.in  = SysInStream.make(socket.getInputStream(), getInBufferSize(fan));
    this.out = SysOutStream.make(socket.getOutputStream(), getOutBufferSize(fan));
  }

  public InStream in(TcpSocket fan)
  {
    if (in == null) throw IOErr.make("not connected");
    return in;
  }

  public OutStream out(TcpSocket fan)
  {
    if (out == null) throw IOErr.make("not connected");
    return out;
  }

  public boolean close(TcpSocket fan)
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

  public void close()
    throws IOException
  {
    socket.close();
    this.in  = null;
    this.out = null;
  }

  public void shutdownIn(TcpSocket fan)
  {
    try
    {
      socket.shutdownInput();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void shutdownOut(TcpSocket fan)
  {
    try
    {
      socket.shutdownOutput();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Streaming Options
//////////////////////////////////////////////////////////////////////////

  public Long getInBufferSize(TcpSocket fan)
  {
    return (inBufSize <= 0) ? null : Long.valueOf(inBufSize);
  }

  public void setInBufferSize(TcpSocket fan, Long v)
  {
    if (in != null) throw Err.make("Must set inBufferSize before connection");
    inBufSize = (v == null) ? 0 : v.intValue();
  }

  public Long getOutBufferSize(TcpSocket fan)
  {
    return (outBufSize <= 0) ? null : Long.valueOf(outBufSize);
  }

  public void setOutBufferSize(TcpSocket fan, Long v)
  {
    if (in != null) throw Err.make("Must set outBufSize before connection");
    outBufSize = (v == null) ? 0 : v.intValue();
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public SocketOptions options(TcpSocket fan)
  {
    if (options == null) options = SocketOptions.make(fan);
    return options;
  }

  public boolean getKeepAlive(TcpSocket fan)
  {
    try
    {
      return socket.getKeepAlive();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setKeepAlive(TcpSocket fan, boolean v)
  {
    try
    {
      socket.setKeepAlive(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long getReceiveBufferSize(TcpSocket fan)
  {
    try
    {
      return socket.getReceiveBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReceiveBufferSize(TcpSocket fan, long v)
  {
    try
    {
      socket.setReceiveBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long getSendBufferSize(TcpSocket fan)
  {
    try
    {
      return socket.getSendBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setSendBufferSize(TcpSocket fan, long v)
  {
    try
    {
      socket.setSendBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean getReuseAddr(TcpSocket fan)
  {
    try
    {
      return socket.getReuseAddress();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReuseAddr(TcpSocket fan, boolean v)
  {
    try
    {
      socket.setReuseAddress(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Duration getLinger(TcpSocket fan)
  {
    try
    {
      int linger = socket.getSoLinger();
      if (linger < 0) return null;
      return Duration.makeSec(linger);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setLinger(TcpSocket fan, Duration v)
  {
    try
    {
      if (v == null)
        socket.setSoLinger(false, 0);
      else
        socket.setSoLinger(true, (int)(v.sec()));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Duration getReceiveTimeout(TcpSocket fan)
  {
    try
    {
      int timeout = socket.getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReceiveTimeout(TcpSocket fan, Duration v)
  {
    try
    {
      if (v == null)
        socket.setSoTimeout(0);
      else
        socket.setSoTimeout((int)(v.millis()));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean getNoDelay(TcpSocket fan)
  {
    try
    {
      return socket.getTcpNoDelay();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setNoDelay(TcpSocket fan, boolean v)
  {
    try
    {
      socket.setTcpNoDelay(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long getTrafficClass(TcpSocket fan)
  {
    try
    {
      return socket.getTrafficClass();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setTrafficClass(TcpSocket fan, long v)
  {
    try
    {
      socket.setTrafficClass((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Socket socket;
  private int inBufSize = 4096;
  private int outBufSize = 4096;
  private IpAddr remoteAddr;
  private int remotePort;
  private SysInStream in;
  private SysOutStream out;
  private SocketOptions options;
}