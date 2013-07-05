//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//

using concurrent

class MulticastSocketTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    s := MulticastSocket.make
    verifyEq(s.isBound, false)
    verifyEq(s.isConnected, false)
    verifyEq(s.isClosed, false)
    verifyEq(s.localAddr, null)
    verifyEq(s.localPort, null)
    verifyEq(s.remoteAddr, null)
    verifyEq(s.remotePort, null)
    verifyEq(s.timeToLive, 1)
    verifyEq(s.interface.name.isEmpty, false)
    s.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /*
  Void dump(MulticastSocket s)
  {
    echo("---------")
    echo("bound        = $s.isBound")
    echo("connected    = $s.isConnected")
    echo("closed       = $s.isClosed")
    echo("localAddr    = $s.localAddr")
    echo("localPort    = $s.localPort")
    echo("remoteAddr   = $s.remoteAddr")
    echo("remotePort   = $s.remotePort")
    echo("receive      = $s.options.receiveBufferSize")
    echo("send         = $s.options.sendBufferSize")
    echo("reuseAddr    = $s.options.reuseAddr")
    echo("timeout      = $s.options.receiveTimeout")
    echo("trafficCls   = 0x$s.options.trafficClass.toHex")
    echo("loopbackMode = $s.loopbackMode")
    echo("ttl          = $s.timeToLive")
    echo("interface    = $s.interface")
  }
  */

}