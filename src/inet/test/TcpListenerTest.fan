//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

class TcpListenerTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    s := TcpListener.make
    verifyEq(s.isBound, false)
    verifyEq(s.isClosed, false)
    verifyEq(s.localAddress, null)
    verifyEq(s.localPort, null)
    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Bind
//////////////////////////////////////////////////////////////////////////

  Void testBind()
  {
    verifyBind(null, null)
    verifyBind(IpAddress.local, null)
    verifyBind(null, 1872)
    verifyBind(IpAddress.local, 1873)
  }

  Void verifyBind(IpAddress? addr, Int? port)
  {
    s := TcpListener.make
    verifySame(s.bind(addr, port), s)

    // state
    verifyEq(s.isBound, true)
    verifyEq(s.isClosed, false)

    // local address
    if (addr == null)
      verify(s.localAddress != null)
    else
      verifyEq(s.localAddress, addr)

    // local port
    if (port == null)
      verify(s.localPort > 0)
    else
      verifyEq(s.localPort, port)

    // duplicate port
    x := TcpSocket.make
    verifyErr(IOErr#) |,| { x.bind(null, s.localPort) }

    // cleanup
    s.close
    x.close

    verifyEq(s.isClosed, true)
  }

//////////////////////////////////////////////////////////////////////////
// Accept
//////////////////////////////////////////////////////////////////////////

  Void testAccept()
  {
    listener := TcpListener.make.bind(null, null)

    t1 := Duration.now
    listener.options.receiveTimeout = 100ms
    verifyErr(IOErr#) |,| { listener.accept }
    t2 := Duration.now
    verify(80ms < t2-t1 && t2-t1 < 150ms)

    thread := Thread(null, &runClient(listener.localPort)).start

    // accept
    trace("s: accept...")
    s := listener.accept
    trace("s: accepted!")
    verifyEq(s.isConnected, true)

    // read req line
    req := s.in.readLine
    trace("s: req = $req")
    verifyEq(req, "hello")

    // write response and verify it is returned back on join
    s.out.printLine("how you doing?").flush
    res := thread.join
    trace("s: response = $res")
    verifyEq(res, "how you doing?")

    // cleanup
    s.close
    listener.close
  }

  static Obj runClient(Int port)
  {
    trace("c: connecting...")
    s := TcpSocket.make.connect(IpAddress.local, port)
    trace("c: connected!")
    s.out.printLine("hello").flush
    res := s.in.readLine
    trace("c: response $res")
    s.close
    return res
  }

  static Void trace(Str s)
  {
    // echo(s)
  }

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  Void testOptions()
  {
    s := TcpListener.make
    so := s.options

    receive := so.receiveBufferSize
    so.receiveBufferSize = receive*2
    verifyEq(so.receiveBufferSize, receive*2)

    reuse := so.reuseAddress
    so.reuseAddress = !reuse
    verifyEq(so.reuseAddress, !reuse)

    so.receiveTimeout = 100ms
    verifyEq(so.receiveTimeout, 100ms)
    so.receiveTimeout = null
    verifyEq(so.receiveTimeout, null)

    verifyErr(UnsupportedErr#) |,| { echo(so.broadcast) }
    verifyErr(UnsupportedErr#) |,| { so.broadcast = false }

    verifyErr(UnsupportedErr#) |,| { echo(so.inBufferSize) }
    verifyErr(UnsupportedErr#) |,| { so.inBufferSize = 88 }

    verifyErr(UnsupportedErr#) |,| { echo(so.outBufferSize) }
    verifyErr(UnsupportedErr#) |,| { so.outBufferSize = 99 }

    verifyErr(UnsupportedErr#) |,| { echo(so.keepAlive) }
    verifyErr(UnsupportedErr#) |,| { so.keepAlive = false }

    verifyErr(UnsupportedErr#) |,| { echo(so.sendBufferSize) }
    verifyErr(UnsupportedErr#) |,| { so.sendBufferSize = 100 }

    verifyErr(UnsupportedErr#) |,| { echo(so.linger) }
    verifyErr(UnsupportedErr#) |,| { so.linger = null }

    verifyErr(UnsupportedErr#) |,| { echo(so.noDelay) }
    verifyErr(UnsupportedErr#) |,| { so.noDelay = true }

    verifyErr(UnsupportedErr#) |,| { echo(so.trafficClass) }
    verifyErr(UnsupportedErr#) |,| { so.trafficClass = 0 }

    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void dump(TcpListener s)
  {
    echo("---------")
    echo("bound      = $s.isBound")
    echo("closed     = $s.isClosed")
    echo("localAddr  = $s.localAddress")
    echo("localPort  = $s.localPort")
    echo("receive    = $s.options.receiveBufferSize")
    echo("reuseAddr  = $s.options.reuseAddress")
    echo("timeout    = $s.options.receiveTimeout")
  }

}