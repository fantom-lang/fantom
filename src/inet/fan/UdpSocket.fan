//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** UdpSocket manages a UDP/IP datagram endpoint.
**
** Note: UdpSocket is marked as a const class to give protocol developers
** the flexibility to process sockets on multiple threads.  However UdpSocket
** is inherently thread unsafe - therefore it is the developers responsibility
** to use this API in a thread safe manner.
**
const class UdpSocket
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a new unbound UDP socket.
  **
  new make() {}

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Is this socket bound to a local address and port.
  **
  native Bool isBound()

  **
  ** Is this socket "connected" to a specific remote host.  Since
  ** UDP is not session oriented, connected just means we've used
  ** connect() to predefine the remote address where we want to
  ** send packets.
  **
  native Bool isConnected()

  **
  ** Is this socket closed.
  **
  native Bool isClosed()

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the bound local address or null if unbound.
  **
  native IpAddr? localAddr()

  **
  ** Get the bound local port or null if unbound.
  **
  native Int? localPort()

  **
  ** Get the remote address or null if not connected to a specific end point.
  **
  native IpAddr? remoteAddr()

  **
  ** Get the remote port or null if not connected to a specific end point.
  **
  native Int? remotePort()

//////////////////////////////////////////////////////////////////////////
// Communication
//////////////////////////////////////////////////////////////////////////

  **
  ** Bind this socket to the specified local address.  If addr is null
  ** then the default IpAddr for the local host is selected.  If port
  ** is null an ephemeral port is selected.  Throw IOErr if the port is
  ** already bound or the bind fails.  Return this.
  **
  native This bind(IpAddr? addr, Int? port)

  **
  ** Connect this socket to the specified address and port.  Once
  ** connected packets may only be send to the remote using this socket.
  **
  native This connect(IpAddr addr, Int port)

  **
  ** Send the packet to its specified remote endpoint.  If this is
  ** socket is connected to a specific remote address, then the packet's
  ** address and port must be null or ArgErr is thrown.  Throw IOErr
  ** on error.
  **
  ** The number of bytes sent is buf.remaining; upon return the buf
  ** is drained and position is advanced.
  **
  native Void send(UdpPacket packet)

  **
  ** Receive a packet on this socket's bound local address.  The resulting
  ** packet is filled in with the sender's address and port.  This method
  ** blocks until a packet is received.  If this socket's receiveTimeout
  ** option is configured, then receive will timeout with an IOErr.
  **
  ** The packet data is read into the Buf starting at it's current position.
  ** The buffer is *not* grown - at most Buf.capacity bytes are received.
  ** If the received message is longer than the packet's capacity then the
  ** message is silently truncated (weird Java behavior).  Upon return the
  ** Buf size and position are updated to reflect the bytes read.  If packet
  ** is null, then a new packet is created with a capacity of 1kb.  The
  ** packet data must always be a memory backed buffer.
  **
  native UdpPacket receive(UdpPacket? packet := null)

  **
  ** Disconnect this socket from its remote address.  Do nothing
  ** if not connected. Return this.
  **
  native This disconnect()

  **
  ** Close this socket.  This method is guaranteed to never throw
  ** an IOErr.  Return true if the socket was closed successfully
  ** or false if the socket was closed abnormally.
  **
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Access the SocketOptions used to tune this socket.  The
  ** following options apply to UdpSockets:
  **   - broadcast
  **   - receiveBufferSize
  **   - sendBufferSize
  **   - reuseAddr
  **   - receiveBufferSize
  **   - trafficClass
  **  Accessing other option fields will throw UnsupportedErr.
  **
  native SocketOptions options()

  internal native Bool getBroadcast()
  internal native Void setBroadcast(Bool v)

  internal native Int getReceiveBufferSize()
  internal native Void setReceiveBufferSize(Int v)

  internal native Int getSendBufferSize()
  internal native Void setSendBufferSize(Int v)

  internal native Bool getReuseAddr()
  internal native Void setReuseAddr(Bool v)

  internal native Duration? getReceiveTimeout()
  internal native Void setReceiveTimeout(Duration? v)

  internal native Int getTrafficClass()
  internal native Void setTrafficClass(Int v)

}