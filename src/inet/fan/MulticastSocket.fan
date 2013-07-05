//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//

**
** MulticastSocket extends UdpSocket to provide multicast capabilities.
**
class MulticastSocket : UdpSocket
{


  **
  ** Make a new unbound multicast UDP socket.
  **
  new make() {}

  **
  ** Default time to live for packets send on this socket.  Value must
  ** be between 0 and 255.  TTL of zero is only delivered locally.
  **
  native Int timeToLive

  **
  ** True to enable outgoing packets to be received by the local socket.
  **
  native Bool loopbackMode

  **
  ** Join a multicast group.  Return this.
  **
  native This joinGroup(IpAddr addr)

  **
  ** Leave a multicast group.  Return this.
  **
  native This leaveGroup(IpAddr addr)

}