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
  new make(SocketConfig config := SocketConfig.cur) : super(config) {}

  **
  ** Default network interface for outgoing datagrams on this socket
  **
  IpInterface interface
  {
    get { getInterface }
    set { setInterface(it) }
  }
  private native IpInterface getInterface()
  private native Void setInterface(IpInterface val)

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
  ** Join a multicast group.  If interface parameter is null,
  ** then `interface` field is used.  Return this.
  **
  native This joinGroup(IpAddr addr, Int? port := null, IpInterface? interface := null)

  **
  ** Leave a multicast group.  If interface parameter is null,
  ** then `interface` field is used.  Return this.
  **
  native This leaveGroup(IpAddr addr, Int? port := null, IpInterface? interface := null)

}