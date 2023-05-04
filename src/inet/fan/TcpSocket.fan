//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

using crypto

**
** TcpSocket manages a TCP/IP endpoint.
**
class TcpSocket
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a new unbound, unconnected TCP socket. The socket will be configured
  ** using the given [socket configuration]`SocketConfig`. The following configuration
  ** applies to a TCP socket:
  **   - `SocketConfig.inBufferSize`
  **   - `SocketConfig.outBufferSize`
  **   - `SocketConfig.keepAlive`
  **   - `SocketConfig.receiveBufferSize`
  **   - `SocketConfig.sendBufferSize`
  **   - `SocketConfig.reuseAddr`
  **   - `SocketConfig.linger`
  **   - `SocketConfig.receiveTimeout`
  **   - `SocketConfig.noDelay`
  **   - `SocketConfig.trafficClass`
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
  ** Get the [socket configuration]`SocketConfig` for this socket.
  **
  native SocketConfig config()

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
  ** longer then the specified timeout before raising an IOErr.  If
  ** timeout is null, then a system default is used.  The default timeout
  ** is configured via `SocketConfig.connectTimeout`.
  **
  native This connect(IpAddr addr, Int port, Duration? timeout := config.connectTimeout)

  **
  ** Get a new TCP socket that is upgraded to use TLS.  If connecting
  ** through a web proxy, specify the destination address and port.
  **
  native TcpSocket upgradeTls(IpAddr? addr := null, Int? port := null)

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

  **
  ** Place input stream for socket at "end of stream".  Any data sent
  ** to input side of socket is acknowledged and then silently discarded.
  ** Raise IOErr if error occurs.
  **
  native Void shutdownIn()

  **
  ** Disables the output stream for this socket. Any previously written
  ** data will be sent followed by TCP's normal connection termination
  ** sequence.  Raise IOErr if error occurs.
  **
  native Void shutdownOut()

//////////////////////////////////////////////////////////////////////////
// Certificates
//////////////////////////////////////////////////////////////////////////

  **
  ** Returns the socket client certificate authentication configuration
  **
  @NoDoc native Str clientAuth()

  **
  ** Returns the certificate(s) that were sent to the remote host during handshake
  **
  @NoDoc native Cert[] localCerts()

  **
  ** Returns the certificate(s) that were sent by the remote host during handshake
  ** with the remote host's own certificate first followed by any certificate
  ** authorities
  **
  ** Note: The returned value may not be a valid certificate chain and should
  ** not be relied on for trust decisions.
  **
  @NoDoc native Cert[] remoteCerts()

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
  @Deprecated { msg = "Use SocketConfig" }
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