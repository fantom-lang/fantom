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
  extends DatagramSocket
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static UdpSocketPeer make(UdpSocket fan)
  {
    try
    {
      return new UdpSocketPeer();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public UdpSocketPeer()
    throws IOException
  {
    super((SocketAddress)null);
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public boolean isBound(UdpSocket fan)
  {
    return isBound();
  }

  public boolean isConnected(UdpSocket fan)
  {
    return isConnected();
  }

  public boolean isClosed(UdpSocket fan)
  {
    return isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddr localAddr(UdpSocket fan)
  {
    if (!isBound()) return null;
    InetAddress addr = getLocalAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(UdpSocket fan)
  {
    if (!isBound()) return null;
    int port = getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

  public IpAddr remoteAddr(UdpSocket fan)
  {
    if (!isConnected()) return null;
    return remoteAddr;
  }

  public Long remotePort(UdpSocket fan)
  {
    if (!isConnected()) return null;
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
      bind(new InetSocketAddress(javaAddr, javaPort));
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public UdpSocket connect(UdpSocket fan, IpAddr addr, long port)
  {
    try
    {
      connect(new InetSocketAddress(addr.peer.java, (int)port));
      this.remoteAddr = addr;
      this.remotePort = (int)port;
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
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
    if (isConnected())
    {
      if (addr != null || port != null)
        throw ArgErr.make("Address and port must be null to send while connected").val;
    }
    else
    {
      if (addr == null || port == null)
        throw ArgErr.make("Address or port is null").val;
      datagram.setAddress(addr.peer.java);
      datagram.setPort(port.intValue());
    }

    // send
    try
    {
      send(datagram);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
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
      receive(datagram);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
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
    disconnect();
    this.remoteAddr = null;
    this.remotePort = -1;
    return fan;
  }

  public boolean close(UdpSocket fan)
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

  public SocketOptions options(UdpSocket fan)
  {
    if (options == null) options = SocketOptions.make(fan);
    return options;
  }

  public boolean getBroadcast(UdpSocket fan)
  {
    try
    {
      return getBroadcast();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setBroadcast(UdpSocket fan, boolean v)
  {
    try
    {
      setBroadcast(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public long getReceiveBufferSize(UdpSocket fan)
  {
    try
    {
      return getReceiveBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setReceiveBufferSize(UdpSocket fan, long v)
  {
    try
    {
      setReceiveBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public long getSendBufferSize(UdpSocket fan)
  {
    try
    {
      return getSendBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setSendBufferSize(UdpSocket fan, long v)
  {
    try
    {
      setSendBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public boolean getReuseAddr(UdpSocket fan)
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

  public void setReuseAddr(UdpSocket fan, boolean v)
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

  public Duration getReceiveTimeout(UdpSocket fan)
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

  public void setReceiveTimeout(UdpSocket fan, Duration v)
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

  public long getTrafficClass(UdpSocket fan)
  {
    try
    {
      return getTrafficClass();
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

  public void setTrafficClass(UdpSocket fan, long v)
  {
    try
    {
      setTrafficClass((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private IpAddr remoteAddr;
  private int remotePort = -1;
  private SocketOptions options;

}