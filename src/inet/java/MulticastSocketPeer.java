//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import fan.sys.*;

public class MulticastSocketPeer extends UdpSocketPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static MulticastSocketPeer make(MulticastSocket fan)
  {
    // use the same instance as the UdpSocket's base class peer
    return (MulticastSocketPeer)((UdpSocket)fan).peer;
  }

  public MulticastSocketPeer(java.net.MulticastSocket socket)
    throws IOException
  {
    super(socket);
    this.socket = socket;
  }

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  public IpInterface getInterface(MulticastSocket fan)
    throws IOException
  {
    try
    {
      return IpInterfacePeer.make(socket.getNetworkInterface());
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }


  public void  setInterface(MulticastSocket fan, IpInterface iface)
    throws IOException
  {
    try
    {
      socket.setNetworkInterface(iface.peer.java);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public long timeToLive(MulticastSocket fan)
    throws IOException
  {
    try
    {
      return socket.getTimeToLive();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void timeToLive(MulticastSocket fan, long ttl)
  {
    try
    {
      socket.setTimeToLive((int)ttl);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean loopbackMode(MulticastSocket fan)
    throws IOException
  {
    try
    {
      // Java uses true for disable
      return !socket.getLoopbackMode();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void loopbackMode(MulticastSocket fan, boolean val)
  {
    try
    {
      // Java uses true for disable
      socket.setLoopbackMode(!val);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public MulticastSocket joinGroup(MulticastSocket fan, IpAddr addr, Long port) { return joinGroup(fan, addr, port, null); }
  public MulticastSocket joinGroup(MulticastSocket fan, IpAddr addr, Long port, IpInterface iface)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = port == null ? 0 : port.intValue();
      NetworkInterface javaIface = (iface == null) ? null : iface.peer.java;
      socket.joinGroup(new InetSocketAddress(javaAddr, javaPort), javaIface);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public MulticastSocket leaveGroup(MulticastSocket fan, IpAddr addr, Long port) { return leaveGroup(fan, addr, port, null); }
  public MulticastSocket leaveGroup(MulticastSocket fan, IpAddr addr, Long port, IpInterface iface)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = port == null ? 0 : port.intValue();
      NetworkInterface javaIface = (iface == null) ? null : iface.peer.java;
      socket.leaveGroup(new InetSocketAddress(javaAddr, javaPort), javaIface);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final java.net.MulticastSocket socket;

}