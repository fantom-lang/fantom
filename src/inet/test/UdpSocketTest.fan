//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

using concurrent

class UdpSocketTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    s := UdpSocket.make
    verifyEq(s.isBound, false)
    verifyEq(s.isConnected, false)
    verifyEq(s.isClosed, false)
    verifyEq(s.localAddr, null)
    verifyEq(s.localPort, null)
    verifyEq(s.remoteAddr, null)
    verifyEq(s.remotePort, null)
    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Bind
//////////////////////////////////////////////////////////////////////////

  Void testBind()
  {
    verifyBind(null, null)
    verifyBind(IpAddr.local, null)
    verifyBind(null, 2072)
    verifyBind(IpAddr.local, 2073)
  }

  Void verifyBind(IpAddr? addr, Int? port)
  {
    s := UdpSocket.make
    verifySame(s.bind(addr, port), s)

    // state
    verifyEq(s.isBound, true)
    verifyEq(s.isConnected, false)
    verifyEq(s.isClosed, false)

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
    x := UdpSocket.make
    verifyErr(IOErr#) { x.bind(null, s.localPort) }
    x.close
    */

    // cleanup
    s.close

    verifyEq(s.isClosed, true)
  }

//////////////////////////////////////////////////////////////////////////
// Messaging
//////////////////////////////////////////////////////////////////////////

  Void testMessaging()
  {
    // launch server
    s := UdpSocket.make.bind(null, null)
    sactor := Actor(ActorPool()) |->| { runServer(s) }
    sfuture := sactor.send(null)
    Actor.sleep(50ms)

    // connect
    c := UdpSocket()
    c.connect(IpAddr.local, s.localPort)
    verifyEq(c.isBound, true)
    verifyEq(c.isConnected, true)
    verifyEq(c.remoteAddr, IpAddr.local)
    verifyEq(c.remotePort, s.localPort)

    // verify addr/port must be null
    verifyErr(ArgErr#) { c.send(UdpPacket(IpAddr.local, null, Buf.make)) }
    verifyErr(ArgErr#) { c.send(UdpPacket(null, s.localPort, Buf.make)) }

    // send "alpha"
    buf := Buf.make
    buf.print("alpha")
    c.send(UdpPacket(null, null, buf.flip))

    // receive "alpha."
    packet := c.receive
    verifyEq(packet.data.capacity, 1024)
    verifyEq(packet.data.flip.readAllStr, "alpha.")

    // send "lo" with pos=3
    buf.clear.print("hello")
    buf.flip
    3.times { buf.read }
    verifyEq(buf.pos, 3)
    c.send(UdpPacket(null, null, buf))

    // receive "lo."
    packet = c.receive
    verifyEq(packet.data.flip.readAllStr, "lo.")

    // disconnect
    c.disconnect
    verifyEq(c.isConnected, false)
    verifyEq(c.remoteAddr, null)
    verifyEq(c.remotePort, null)

    // verify addr/port cannot be null
    verifyErr(ArgErr#) { c.send(UdpPacket(IpAddr.local, null, Buf.make)) }
    verifyErr(ArgErr#) { c.send(UdpPacket(null, s.localPort, Buf.make)) }

    // send "abc"
    c.send(UdpPacket(IpAddr.local, s.localPort, (Buf)buf.clear.print("abc")->flip))

    // receive in Buf.pos=2
    buf.clear.print("xy")
    verifyEq(buf.pos, 2)
    packet = c.receive(UdpPacket(null, null, buf))
    verifyEq(packet.addr, IpAddr.local)
    verifyEq(packet.port, s.localPort)
    verifyEq(packet.data.flip.readAllStr, "xyabc.")

    // send "ABCDEFG"
    c.send(UdpPacket(IpAddr.local, s.localPort, (Buf)buf.clear.print("ABCDEFG")->flip))

    // receive with capacity too small and validate truncating
    buf.clear.capacity = 3
    verifyEq(buf.pos, 0)
    verifyEq(buf.capacity, 3)
    c.receive(packet)
    verifyEq(packet.addr, IpAddr.local)
    verifyEq(packet.port, s.localPort)
    verifyEq(packet.data.flip.readAllStr, "ABC")

    // send "0123456789"
    c.send(UdpPacket(IpAddr.local, s.localPort, (Buf)buf.clear.print("0123456789")->flip))

    // receive with capacity too small and pos=2 to validate truncating
    buf.clear.capacity = 5
    buf.print("qr")
    verifyEq(buf.pos, 2)
    verifyEq(buf.capacity, 5)
    c.receive(packet)
    verifyEq(packet.addr, IpAddr.local)
    verifyEq(packet.port, s.localPort)
    verifyEq(packet.data.flip.readAllStr, "qr012")

    // reconnect
    c.connect(IpAddr.local, s.localPort)
    verifyEq(c.isConnected, true)
    verifyEq(c.remoteAddr, IpAddr.local)
    verifyEq(c.remotePort, s.localPort)

    // send kill and join
    c.send(UdpPacket(null, null, (Buf)buf.clear.print("kill")->flip))
    sfuture.get(5sec)

    //cleanup
    s.close
    c.close
  }

  static Str runServer(UdpSocket s)
  {
    while (true)
    {
      // receive an ASCII string
      packet := s.receive
      req := packet.data.flip.readAllStr
      if (req == "kill") break

      // reflect string with "." appended
      packet.data.print(".")
      packet.data.flip
      s.send(packet)
    }
    return "ok"
  }

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  Void testOptions()
  {
    s := UdpSocket.make
    so := s.options

    broadcast := so.broadcast
    so.broadcast = !broadcast
    verifyEq(so.broadcast, !broadcast)

    receive := so.receiveBufferSize
    so.receiveBufferSize = receive*2
    verifyEq(so.receiveBufferSize, receive*2)

    send := so.sendBufferSize
    so.sendBufferSize = send/2
    verifyEq(so.sendBufferSize, send/2)

    reuse := so.reuseAddr
    so.reuseAddr = !reuse
    verifyEq(so.reuseAddr, !reuse)

    so.receiveTimeout = 100ms
    verifyEq(so.receiveTimeout, 100ms)
    so.receiveTimeout = null
    verifyEq(so.receiveTimeout, null)

    tc := so.trafficClass
    so.trafficClass = 0x6
    verifyEq(so.trafficClass, 0x6)

    verifyErr(UnsupportedErr#) { echo(so.inBufferSize) }
    verifyErr(UnsupportedErr#) { so.inBufferSize = 88 }

    verifyErr(UnsupportedErr#) { echo(so.outBufferSize) }
    verifyErr(UnsupportedErr#) { so.outBufferSize = 99 }

    verifyErr(UnsupportedErr#) { echo(so.keepAlive) }
    verifyErr(UnsupportedErr#) { so.keepAlive = false }

    verifyErr(UnsupportedErr#) { echo(so.linger) }
    verifyErr(UnsupportedErr#) { so.linger = null }

    verifyErr(UnsupportedErr#) { echo(so.noDelay) }
    verifyErr(UnsupportedErr#) { so.noDelay = true }

    xo := TcpSocket().options
    xo.copyFrom(so)
    verifyEq(xo.broadcast, so.broadcast)
    verifyEq(xo.receiveBufferSize, so.receiveBufferSize)
    verifyEq(xo.sendBufferSize, so.sendBufferSize)
    verifyEq(xo.reuseAddr, so.reuseAddr)
    verifyEq(xo.receiveTimeout, so.receiveTimeout)

    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /*
  Void dump(UdpSocket s)
  {
    echo("---------")
    echo("bound      = $s.isBound")
    echo("connected  = $s.isConnected")
    echo("closed     = $s.isClosed")
    echo("localAddr  = $s.localAddr")
    echo("localPort  = $s.localPort")
    echo("remoteAddr = $s.remoteAddr")
    echo("remotePort = $s.remotePort")
    echo("receive    = $s.options.receiveBufferSize")
    echo("send       = $s.options.sendBufferSize")
    echo("reuseAddr  = $s.options.reuseAddr")
    echo("timeout    = $s.options.receiveTimeout")
    echo("trafficCls = 0x$s.options.trafficClass.toHex")
  }
  */

}