//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 07  Brian Frank  Creation
//

**
** TcpListener is a server socket that listens to a local well
** known port for incoming TcpSockets.
**
class TcpListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a new, unbound TCP server socket. The socket will be configured
  ** using the given [socket configuration]`SocketConfig`. The following
  ** configuration applies to listeners:
  **   - `SocketConfig.receiveBufferSize`
  **   - `SocketConfig.reuseAddr`
  **   - `SocketConfig.acceptTimeout`
  **
  new make(SocketConfig config := SocketConfig.cur)
  {
    init(config)
  }

  private native This init(SocketConfig config)

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** The `SocketConfig` being used to configure the server sockets.
  **
  native SocketConfig config()

  **
  ** Is this socket bound to a local address and port.
  **
  native Bool isBound()

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

//////////////////////////////////////////////////////////////////////////
// Communication
//////////////////////////////////////////////////////////////////////////

  **
  ** Bind this listener to the specified local address.  If addr is null
  ** then the default IpAddr for the local host is selected.  If port
  ** is null an ephemeral port is selected.  Throw IOErr if the port is
  ** already bound or the bind fails.  Return this.
  **
  native This bind(IpAddr? addr, Int? port, Int backlog := 50)

  **
  ** Accept the next incoming connection.  This method blocks the
  ** calling thread until a new connection is established.  If this
  ** listener's `SocketConfig.acceptTimeout` is configured, then accept
  ** will timeout with an IOErr.
  **
  TcpSocket accept() { return doAccept }
  private native TcpSocket doAccept()

  **
  ** Close this server socket.  This method is guaranteed to never
  ** throw an IOErr.  Return true if the socket was closed successfully
  ** or false if the socket was closed abnormally.
  **
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Access the SocketOptions used to tune this server socket.
  ** The following options apply to TcpListeners:
  **   - receiveBufferSize
  **   - reuseAddr
  **  Accessing other option fields will throw UnsupportedErr.
  **
  @Deprecated { msg = "Use SocketConfig" }
  SocketOptions options()
  {
    return SocketOptions(this)
  }

  internal native Int getReceiveBufferSize()
  internal native Void setReceiveBufferSize(Int v)

  internal native Bool getReuseAddr()
  internal native Void setReuseAddr(Bool v)
}
