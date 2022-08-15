//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 2021  Matthew Giannini  Creation
//

using concurrent
using crypto

**
** Configuration options for TCP and UDP sockets. All socket types accept
** a socket configuration which will be used to configure the socket when
** it is created.
**
** A system-wide default socket configuration can be obtained with
** `SocketConfig.cur`. You can change the system default by using
** `SocketConfig.setCur`.
**
** See `TcpSocket.make`, `TcpListener.make`, `UdpSocket.make`, `MulticastSocket.make`
**
const class SocketConfig
{

//////////////////////////////////////////////////////////////////////////
// Cur
//////////////////////////////////////////////////////////////////////////

  ** Get the current, default socket configuration
  static SocketConfig cur() { curRef.val }

  ** Set a new default socket configuration. This configuration will
  ** only apply to new sockets created after this is called. This
  ** method may only be called **once** to change the default socket configuration.
  static Void setCur(SocketConfig cfg)
  {
    if (errRef.val != null) throw Err("Default socket configuration already set", errRef.val)
    curRef.val = cfg
    errRef.val = Err("Default socket configuration changed")
  }

  private static const AtomicRef curRef := AtomicRef(SocketConfig())
  private static const AtomicRef errRef := AtomicRef()

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Create and configure the socket options.
  new make(|This|? f := null)
  {
    f?.call(this)
  }

  @NoDoc protected new makeCopy(SocketConfig? orig, |This| f)
  {
    if (orig != null)
    {
      this.keystore          = orig.keystore
      this.truststore        = orig.truststore
      this.tlsParams         = orig.tlsParams

      this.inBufferSize      = orig.inBufferSize
      this.keepAlive         = orig.keepAlive
      this.receiveBufferSize = orig.receiveBufferSize
      this.sendBufferSize    = orig.sendBufferSize
      this.reuseAddr         = orig.reuseAddr
      this.linger            = orig.linger
      this.connectTimeout    = orig.connectTimeout
      this.receiveTimeout    = orig.receiveTimeout
      this.acceptTimeout     = orig.acceptTimeout
      this.noDelay           = orig.noDelay
      this.trafficClass      = orig.trafficClass

      this.broadcast         = orig.broadcast
    }
    f(this)
  }

  ** Create a copy of this configuration and then apply any overrides from the it-block.
  virtual This copy(|This| f) { makeCopy(this, f) }

  ** Convenience to create a copy of this socket configuration and set the connect
  ** and receive timeouts to the given duration. Setting to 'null' indicates
  ** infinite timeouts.
  This setTimeouts(Duration? connectTimeout, Duration? receiveTimeout := connectTimeout)
  {
    copy { it.connectTimeout = connectTimeout; it.receiveTimeout = receiveTimeout }
  }

  private native Void force_peer()

//////////////////////////////////////////////////////////////////////////
// Tls Config
//////////////////////////////////////////////////////////////////////////

  ** The `crypto::KeyStore` to use when creating secure sockets. If null, the runtime
  ** default will be used.
  const KeyStore? keystore := null

  ** The `crypto::KeyStore` to use for obtaining trusted certificates when creating
  ** secure sockets. If null, the runtime default will be used.
  const KeyStore? truststore := null

  ** TCP sockets that are upgraded to TLS will be configured with these parameters.
  ** The following parameters are supported:
  ** - 'appProtocols': ('Str[]') prioritized array of application-layer protocol
  ** names that can be negotiated over the TLS protocol
  ** - 'clientAuth': ('Str') determine client certificate authentication configuration
  ** of socket.  Supported values:
  **   - 'want': Configure socket to request client authentication
  **   - 'need': Configure socket to require client authentication
  **   - 'none': (Default) socket does not request or require client authentication
  **
  ** **Experimental - this functionality is subject to change**
  @NoDoc const Str:Obj? tlsParams := [:]

//////////////////////////////////////////////////////////////////////////
// Socket Config
//////////////////////////////////////////////////////////////////////////


  ** The size in bytes for the sys::InStream buffer. A value of 0 or
  ** null disables input stream buffing.
  const Int? inBufferSize := 4096

  ** The size in bytes for the sys::OutStream buffer. A value of 0 or
  ** null disables output stream buffing.
  const Int? outBufferSize := 4096

  ** 'SO_KEEPALIVE' option
  const Bool keepAlive := false

  ** 'SO_RCVBUF' option for the size in bytes of the IP stack buffers.
  const Int receiveBufferSize := 65_536

  ** 'SO_SNDBUF' option for the size in bytes of the IP stack buffers.
  const Int sendBufferSize := 65_536

  ** 'SO_REUSEADDR' is used to control the time wait state of a closed socket.
  const Bool reuseAddr := false

  ** 'SO_LINGER' controls the linger time or set to null to disable linger.
  const Duration? linger := null

  ** Controls the default timeout used by `TcpSocket.connect`.
  ** A null value indicates a system default timeout (usually wait forever).
  const Duration? connectTimeout  := 60sec

  ** 'SO_TIMEOUT' controls the amount of time a socket
  ** will block on a read call before throwing an IOErr timeout exception.
  ** 'null' is used to indicate an infinite timeout.
  const Duration? receiveTimeout := 60sec

  ** Controls how long a `TcpListener.accept` will block before throwing an
  ** IOErr timeout exception. 'null' is used to indicate infinite timeout.
  const Duration? acceptTimeout := null

  ** 'TCP_NODELAY' socket option specifies that send not be delayed
  ** to merge packets (Nagle's algorthm).
  const Bool noDelay := true

  ** The type-of-class byte in the IP packet header.
  **
  ** For IPv4 this value is detailed in RFC 1349 as the following bitset:
  **  - IPTOS_LOWCOST     (0x02)
  **  - IPTOS_RELIABILITY (0x04)
  **  - IPTOS_THROUGHPUT  (0x08)
  **  - IPTOS_LOWDELAY    (0x10)
  **
  ** For IPv6 this is the value placed into the sin6_flowinfo header field.
  const Int trafficClass := 0

  ** 'SO_BROADCAST' socket option
  const Bool broadcast := false

}