//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

class TcpSocketTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    s := TcpSocket.make
    verifyEq(s.isBound, false)
    verifyEq(s.isConnected, false)
    verifyEq(s.isClosed, false)
    verifyEq(s.localAddr, null)
    verifyEq(s.localPort, null)
    verifyEq(s.remoteAddr, null)
    verifyEq(s.remotePort, null)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }
    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Bind
//////////////////////////////////////////////////////////////////////////

  Void testBind()
  {
    verifyBind(null, null)
    verifyBind(IpAddr.local, null)
    port := (1200..9999).random
    verifyBind(null, port)
    verifyBind(IpAddr.local, port)
  }

  Void verifyBind(IpAddr? addr, Int? port)
  {
    s := TcpSocket.make
    verifySame(s.bind(addr, port), s)

    // state
    verifyEq(s.isBound, true)
    verifyEq(s.isConnected, false)
    verifyEq(s.isClosed, false)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }

    // local address
    if (addr == null)
      verify(s.localAddr != null)
    else
      verifyEq(s.localAddr, addr)

    // local port
    if (port == null)
      verify(s.localPort > 0)
    else
      verifyEq(s.localPort, port)

    // null remote
    verifyEq(s.remoteAddr, null)
    verifyEq(s.remotePort, null)

    // duplicate port
    /* On Windows7 this doesn't fail?
    x := TcpSocket.make
    verifyErr(IOErr#) { x.bind(null, s.localPort) }
    x.close
    */

    // cleanup
    s.close

    verifyEq(s.isClosed, true)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }
  }

//////////////////////////////////////////////////////////////////////////
// Connection Failures
//////////////////////////////////////////////////////////////////////////

  Void testConnectFailures()
  {
    // local, invalid port
    s := TcpSocket.make
    verifyErr(IOErr#) { s.connect(IpAddr.local, 1969) }
    verifyEq(s.isConnected, false)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }
    s.close

    // invalid host
    t1 := Duration.now
    s = TcpSocket.make
    verifyErr(IOErr#) { s.connect(IpAddr("1.1.1.1"), 1969, 100ms) }
    t2 := Duration.now
    verifyEq(s.isConnected, false)
    verify(80ms < t2-t1 && t2-t1 < 150ms)
    s.close

    verifyEq(s.isClosed, true)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }
  }

//////////////////////////////////////////////////////////////////////////
// Connect
//////////////////////////////////////////////////////////////////////////

  Void testConnectHttp()
  {
    doTestConnectHttp(null)
    doTestConnectHttp(30sec)
  }

  Void doTestConnectHttp(Duration? timeout)
  {
    // connect to www server
    s := TcpSocket().connect(IpAddr("hg.fantom.org"), 80, timeout)

    // verify connetion state
    verifyEq(s.isBound, true)
    verifyEq(s.isConnected, true)
    verifyEq(s.isClosed, false)
    verify((Obj?)s.in != null)
    verify((Obj?)s.out != null)
    verifyErr(Err#) { s.options.inBufferSize = 16 }
    verifyErr(Err#) { s.options.outBufferSize = 16 }

    // send very simple request line
    s.out.print("GET / HTTP/1.0\r\n\r\n").flush

    // read first response line
    res := s.in.readLine
    verify(res.startsWith("HTTP/"))

    // cleanup
    s.close
    verifyEq(s.isClosed, true)
    verifyErr(IOErr#) { s.in }
    verifyErr(IOErr#) { s.out }
  }

//////////////////////////////////////////////////////////////////////////
// Fork
//////////////////////////////////////////////////////////////////////////

  /* TODO - remove when we finalize that TcpSocket should be const
  Void testFork()
  {
    // verify duplicate name
    verifyErr(ArgErr#)
    {
       x := TcpSocket().connect(IpAddr("fantom.org"), 80)
       x.fork(Thread.current.name, &runFork(x.localPort, x.remoteAddr.numeric))
    }

    // verify non-const method
    verifyErr(NotImmutableErr#)
    {
       x := TcpSocket().connect(IpAddr("fantom.org"), 80)
       x.fork(null) |TcpSocket s| { fail }
    }

    // connect to www server
    s := TcpSocket().connect(IpAddr("fantom.org"), 80)
    so := s.options

    // fork
    t := s.fork(null, &runFork(s.localPort, s.remoteAddr.numeric))

    // verify that all methods on s now throw UnsupportedErr
    verifyErr(UnsupportedErr#) { s.isBound }
    verifyErr(UnsupportedErr#) { s.isConnected }
    verifyErr(UnsupportedErr#) { s.isClosed }
    verifyErr(UnsupportedErr#) { s.localAddr }
    verifyErr(UnsupportedErr#) { s.localPort }
    verifyErr(UnsupportedErr#) { s.remoteAddr }
    verifyErr(UnsupportedErr#) { s.remotePort  }
    verifyErr(UnsupportedErr#) { s.bind(null, null) }
    verifyErr(UnsupportedErr#) { s.connect(null, null) }
    verifyErr(UnsupportedErr#) { s.in }
    verifyErr(UnsupportedErr#) { s.out }
    verifyErr(UnsupportedErr#) { s.close }
    verifyErr(UnsupportedErr#) { s.fork(null, null) }
    verifyErr(UnsupportedErr#) { s.options }

    // verify that all socket options now throw UnsupportedErr
    verifyErr(UnsupportedErr#) { echo(so.inBufferSize) }
    verifyErr(UnsupportedErr#) { so.inBufferSize = 100}
    verifyErr(UnsupportedErr#) { echo(so.outBufferSize) }
    verifyErr(UnsupportedErr#) { so.outBufferSize = 100}
    verifyErr(UnsupportedErr#) { echo(so.keepAlive) }
    verifyErr(UnsupportedErr#) { so.keepAlive = false }
    verifyErr(UnsupportedErr#) { echo(so.receiveBufferSize) }
    verifyErr(UnsupportedErr#) { so.receiveBufferSize = 10}
    verifyErr(UnsupportedErr#) { echo(so.sendBufferSize) }
    verifyErr(UnsupportedErr#) { so.sendBufferSize = 10}
    verifyErr(UnsupportedErr#) { echo(so.linger) }
    verifyErr(UnsupportedErr#) { so.linger = null }
    verifyErr(UnsupportedErr#) { echo(so.receiveTimeout) }
    verifyErr(UnsupportedErr#) { so.receiveTimeout = null }
    verifyErr(UnsupportedErr#) { echo(so.noDelay) }
    verifyErr(UnsupportedErr#) { so.noDelay = false }
    verifyErr(UnsupportedErr#) { echo(so.trafficClass) }
    verifyErr(UnsupportedErr#) { so.trafficClass = 0 }

    // join and verify response
    verifyEq(t.join, "HTTP/1.1 200 OK")
  }

  static Obj runFork(Int localPort, Str remoteAddr, TcpSocket s)
  {
    // verify state of new detached socket
    if (s.localPort != localPort) return null
    if (s.remoteAddr.numeric != remoteAddr) return null
    if (s.remotePort != 80) return null

    // send very simple request line
    s.out.print("GET / HTTP/1.0\n\r\n\r").flush

    // read first response line
    res := s.in.readLine

    // cleanup and return response
    s.close
    return res
  }
  */

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  Void testOptions()
  {
    s := TcpSocket.make
    so := s.options

    in := so.inBufferSize
    so.inBufferSize = in*2
    verifyEq(so.inBufferSize, in*2)

    out := so.outBufferSize
    so.outBufferSize = in*2+1
    verifyEq(so.outBufferSize, in*2+1)

    keepAlive := so.keepAlive
    so.keepAlive = !keepAlive
    verifyEq(so.keepAlive, !keepAlive)

    receive := so.receiveBufferSize
    so.receiveBufferSize = receive*2
    verifyEq(so.receiveBufferSize, receive*2)

    send := so.sendBufferSize
    so.sendBufferSize = send*4
    verifyEq(so.sendBufferSize, send*4)

    reuse := so.reuseAddr
    so.reuseAddr = !reuse
    verifyEq(so.reuseAddr, !reuse)

    so.linger = 2sec
    verifyEq(so.linger, 2sec)
    so.linger = null
    verifyEq(so.linger, null)

    so.receiveTimeout = 100ms
    verifyEq(so.receiveTimeout, 100ms)
    so.receiveTimeout = null
    verifyEq(so.receiveTimeout, null)

    verifyEq(so.noDelay, true) // should default to false
    so.noDelay = false
    verifyEq(so.noDelay, false)

    tc := so.trafficClass
    so.trafficClass = 0x6
    verifyEq(so.trafficClass, 0x6)

    verifyErr(UnsupportedErr#) { echo(so.broadcast) }
    verifyErr(UnsupportedErr#) { so.broadcast = false }

    xo := TcpSocket().options
    xo.copyFrom(so)
    verifyEq(xo.inBufferSize, so.inBufferSize)
    verifyEq(xo.outBufferSize, so.outBufferSize)
    verifyEq(xo.keepAlive, so.keepAlive)
    verifyEq(xo.receiveBufferSize, so.receiveBufferSize)
    verifyEq(xo.sendBufferSize, so.sendBufferSize)
    verifyEq(xo.reuseAddr, so.reuseAddr)
    verifyEq(xo.linger, so.linger)
    verifyEq(xo.receiveTimeout, so.receiveTimeout)
    verifyEq(xo.noDelay, so.noDelay)
    verifyEq(xo.trafficClass, so.trafficClass)

    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /*
  Void dump(TcpSocket s)
  {
    echo("---------")
    echo("bound      = $s.isBound")
    echo("connected  = $s.isConnected")
    echo("closed     = $s.isClosed")
    echo("localAddr  = $s.localAddr")
    echo("localPort  = $s.localPort")
    echo("remoteAddr = $s.remoteAddr")
    echo("remotePort = $s.remotePort")
    echo("keepAlive  = $s.options.keepAlive")
    echo("receive    = $s.options.receiveBufferSize")
    echo("send       = $s.options.sendBufferSize")
    echo("reuseAddr  = $s.options.reuseAddr")
    echo("linger     = $s.options.linger")
    echo("timeout    = $s.options.receiveTimeout")
    echo("noDelay    = $s.options.noDelay")
    echo("trafficCls = 0x$s.options.trafficClass.toHex")
  }
  */

}