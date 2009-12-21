//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** TcpSocket manages a TCP/IP endpoint.
**
** Note: TcpSocket is marked as a const class to give protocol developers
** the flexibility to process sockets on multiple threads.  However TcpSocket
** is inherently thread unsafe - therefore it is the developers responsibility
** to use this API in a thread safe manner.
**
const class TcpSocket
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a new unbound, unconnected TCP socket.
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
  ** Is this socket connected to the remote host.
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
  ** Get the remote address or null if not connected.
  **
  native IpAddr? remoteAddr()

  **
  ** Get the remote port or null if not connected.
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
  ** Connect this socket to the specified address and port.  This method
  ** will block until the connection is made.  Throw IOErr if there is a
  ** connection error.  If a non-null timeout is specified, then block no
  ** longer then the specified timeout before raising an IOErr.
  **
  native This connect(IpAddr addr, Int port, Duration? timeout := null)

  **
  ** Get the input stream used to read data from the socket.  The input
  ** stream is automatically buffered according to SocketOptions.inBufferSize.
  ** If not connected then throw IOErr.
  **
  native InStream in()

  **
  ** Get the output stream used to write data to the socket.  The output
  ** stream is automatically buffered according to SocketOptions.outBufferSize
  ** If not connected then throw IOErr.
  **
  native OutStream out()

  **
  ** Close this socket and its associated IO streams.  This method is
  ** guaranteed to never throw an IOErr.  Return true if the socket was
  ** closed successfully or false if the socket was closed abnormally.
  **
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Access the SocketOptions used to tune this socket.  The
  ** following options apply to TcpSockets:
  **   - inBufferSize
  **   - outBufferSize
  **   - keepAlive
  **   - receiveBufferSize
  **   - sendBufferSize
  **   - reuseAddr
  **   - linger
  **   - receiveTimeout
  **   - noDelay
  **   - trafficClass
  **  Accessing other option fields will throw UnsupportedErr.
  **
  native SocketOptions options()

  internal native Int? getInBufferSize()
  internal native Void setInBufferSize(Int? v)

  internal native Int? getOutBufferSize()
  internal native Void setOutBufferSize(Int? v)

  internal native Bool getKeepAlive()
  internal native Void setKeepAlive(Bool v)

  internal native Int getReceiveBufferSize()
  internal native Void setReceiveBufferSize(Int v)

  internal native Int getSendBufferSize()
  internal native Void setSendBufferSize(Int v)

  internal native Bool getReuseAddr()
  internal native Void setReuseAddr(Bool v)

  internal native Duration? getLinger()
  internal native Void setLinger(Duration? v)

  internal native Duration? getReceiveTimeout()
  internal native Void setReceiveTimeout(Duration? v)

  internal native Bool getNoDelay()
  internal native Void setNoDelay(Bool v)

  internal native Int getTrafficClass()
  internal native Void setTrafficClass(Int v)

}