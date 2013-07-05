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
    try
    {
      return new MulticastSocketPeer(new java.net.MulticastSocket((SocketAddress)null));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
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

  public UdpSocket joinGroup(UdpSocket fan, IpAddr addr)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      socket.joinGroup(javaAddr);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public UdpSocket leaveGroup(UdpSocket fan, IpAddr addr)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      socket.leaveGroup(javaAddr);
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