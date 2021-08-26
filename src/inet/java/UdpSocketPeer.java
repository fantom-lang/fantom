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

public class UdpSocketPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static UdpSocketPeer make(UdpSocket fan)
  {
    try
    {
      if (fan instanceof MulticastSocket)
        return new MulticastSocketPeer(new java.net.MulticastSocket((SocketAddress)null));
      else
        return new UdpSocketPeer(new DatagramSocket((SocketAddress)null));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public UdpSocket init(UdpSocket fan, SocketConfig config)
  {
    this.config = config;
    setBroadcast(fan, config.broadcast);
    setReceiveBufferSize(fan, config.receiveBufferSize);
    setSendBufferSize(fan, config.sendBufferSize);
    setReuseAddr(fan, config.reuseAddr);
    setReceiveTimeout(fan, config.receiveTimeout);
    setTrafficClass(fan, config.trafficClass);
    return fan;
  }

  public UdpSocketPeer(DatagramSocket socket)
    throws IOException
  {
    this.socket = socket;
  }

  public SocketConfig config() { return this.config; }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public boolean isBound(UdpSocket fan)
  {
    return socket.isBound();
  }

  public boolean isConnected(UdpSocket fan)
  {
    return socket.isConnected();
  }

  public boolean isClosed(UdpSocket fan)
  {
    return socket.isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddr localAddr(UdpSocket fan)
  {
    if (!socket.isBound()) return null;
    InetAddress addr = socket.getLocalAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(UdpSocket fan)
  {
    if (!socket.isBound()) return null;
    int port = socket.getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

  public IpAddr remoteAddr(UdpSocket fan)
  {
    if (!socket.isConnected()) return null;
    return remoteAddr;
  }

  public Long remotePort(UdpSocket fan)
  {
    if (!socket.isConnected()) return null;
    return Long.valueOf(remotePort);
  }

//////////////////////////////////////////////////////////////////////////
// Communication
//////////////////////////////////////////////////////////////////////////

  public UdpSocket bind(UdpSocket fan, IpAddr addr, Long port)
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

  public UdpSocket connect(UdpSocket fan, IpAddr addr, long port)
  {
    try
    {
      socket.connect(new InetSocketAddress(addr.peer.java, (int)port));
      this.remoteAddr = addr;
      this.remotePort = (int)port;
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void send(UdpSocket fan, UdpPacket packet)
  {
    // map buf bytes to packet
    MemBuf data = (MemBuf)packet.data();
    byte[] buf = data.buf;
    int off = data.pos;
    int len = data.size - off;
    DatagramPacket datagram = new DatagramPacket(buf, off, len);

    // map address, port
    IpAddr addr = packet.addr();
    Long port = packet.port();
    if (socket.isConnected())
    {
      if (addr != null || port != null)
        throw ArgErr.make("Address and port must be null to send while connected");
    }
    else
    {
      if (addr == null || port == null)
        throw ArgErr.make("Address or port is null");
      datagram.setAddress(addr.peer.java);
      datagram.setPort(port.intValue());
    }

    // send
    try
    {
      socket.send(datagram);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }

    // lastly drain buff
    data.pos += len;
  }

  public UdpPacket receive(UdpSocket fan, UdpPacket packet)
  {
    // create packet if null
    if (packet == null)
      packet = UdpPacket.make(null, null, new MemBuf(1024));

    // map buf bytes to packet
    MemBuf data = (MemBuf)packet.data();
    byte[] buf = data.buf;
    int off = data.pos;
    int len = buf.length - off;
    DatagramPacket datagram = new DatagramPacket(buf, off, len);

    // receive
    try
    {
      socket.receive(datagram);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }

    // update packet with received message
    packet.addr(IpAddrPeer.make(datagram.getAddress()));
    packet.port(Long.valueOf(datagram.getPort()));
    data.pos  += datagram.getLength();
    data.size += datagram.getLength();

    return packet;
  }

  public UdpSocket disconnect(UdpSocket fan)
  {
    socket.disconnect();
    this.remoteAddr = null;
    this.remotePort = -1;
    return fan;
  }

  public boolean close(UdpSocket fan)
  {
    try
    {
      socket.close();
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

  public SocketOptions options(UdpSocket fan)
  {
    if (options == null) options = SocketOptions.make(fan);
    return options;
  }

  public boolean getBroadcast(UdpSocket fan)
  {
    try
    {
      return socket.getBroadcast();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setBroadcast(UdpSocket fan, boolean v)
  {
    try
    {
      socket.setBroadcast(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long getReceiveBufferSize(UdpSocket fan)
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

  public void setReceiveBufferSize(UdpSocket fan, long v)
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

  public long getSendBufferSize(UdpSocket fan)
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

  public void setSendBufferSize(UdpSocket fan, long v)
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

  public boolean getReuseAddr(UdpSocket fan)
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

  public void setReuseAddr(UdpSocket fan, boolean v)
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

  public Duration getReceiveTimeout(UdpSocket fan)
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

  public void setReceiveTimeout(UdpSocket fan, Duration v)
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

  public long getTrafficClass(UdpSocket fan)
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

  public void setTrafficClass(UdpSocket fan, long v)
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

  private final DatagramSocket socket;
  private SocketConfig config;
  private IpAddr remoteAddr;
  private int remotePort = -1;
  private SocketOptions options;

}