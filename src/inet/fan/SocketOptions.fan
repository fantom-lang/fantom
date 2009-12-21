//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** SocketOptions groups together all the socket options used to tune a
** TcpSocket, TcpListener, or UdpSocket.  See the options method of each
** of those classes for which options apply.  Accessing an unsupported
** option for a particular socket type will throw UnsupportedErr.
**
final class SocketOptions
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Attach this options instance to the specific socket (we just
  ** use an Obj because everything is dynamically typed)
  **
  internal new make(Obj socket)
  {
    this.socket = socket;
  }

//////////////////////////////////////////////////////////////////////////
// Copy From
//////////////////////////////////////////////////////////////////////////

  **
  ** Set all of this instance's options from the specified options.
  **
  Void copyFrom(SocketOptions options)
  {
    Type.of(this).fields.each |Field f|
    {
      try
        f.set(this, f.get(options))
      catch (UnsupportedErr e)
        {}
    }
  }

//////////////////////////////////////////////////////////////////////////
// Streaming Options
//////////////////////////////////////////////////////////////////////////

  **
  ** The size in bytes for the sys::InStream buffer.  A value of 0 or
  ** null disables input stream buffing.  This field may only be set before
  ** the socket is connected otherwise Err is thrown.
  **
  Int? inBufferSize
  {
    get { return (Int)wrap |->Obj| { return socket->getInBufferSize } }
    set { newVal := it; wrap |->| { socket->setInBufferSize(newVal) } }
  }

  **
  ** The size in bytes for the sys::OutStream buffer.  A value of 0 or
  ** null disables output stream buffing.  This field may only be set before
  ** the socket is connected otherwise Err is thrown.
  **
  Int? outBufferSize
  {
    get { return (Int)wrap |->Obj| { return socket->getOutBufferSize } }
    set { newVal := it; wrap |->| { socket->setOutBufferSize(newVal) } }
  }

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  **
  ** SO_BROADCAST socket option.
  **
  Bool broadcast
  {
    get { return (Bool)wrap |->Obj| { return socket->getBroadcast } }
    set { newVal := it; wrap |->| { socket->setBroadcast(newVal) } }
  }

  **
  ** SO_KEEPALIVE socket option.
  **
  Bool keepAlive
  {
    get { return (Bool)wrap |->Obj| { return socket->getKeepAlive } }
    set { newVal := it; wrap |->| { socket->setKeepAlive(newVal) } }
  }

  **
  ** SO_RCVBUF option for the size in bytes of the IP stack buffers.
  **
  Int receiveBufferSize
  {
    get { return (Int)wrap |->Obj| { return socket->getReceiveBufferSize } }
    set { newVal := it; wrap |->| { socket->setReceiveBufferSize(newVal) } }
  }

  **
  ** SO_SNDBUF option for the size in bytes of the IP stack buffers.
  **
  Int sendBufferSize
  {
    get { return (Int)wrap |->Obj| { return socket->getSendBufferSize } }
    set { newVal := it; wrap |->| { socket->setSendBufferSize(newVal) } }
  }

  **
  ** SO_REUSEADDR socket option is used to control the time
  ** wait state of a closed socket.
  **
  Bool reuseAddr
  {
    get { return (Bool)wrap |->Obj| { return socket->getReuseAddr } }
    set { newVal := it; wrap |->| { socket->setReuseAddr(newVal) } }
  }

  **
  ** SO_LINGER socket option controls the linger time or set
  ** to null to disable linger.
  **
  Duration? linger
  {
    get { return (Duration?)wrap |->Obj?| { return socket->getLinger} }
    set { newVal := it; wrap |->| { socket->setLinger(newVal) } }
  }

  **
  ** SO_TIMEOUT socket option controls the amount of time this socket
  ** will block on a read call before throwing an IOErr timeout exception.
  ** Null is used to indicate an infinite timeout.
  **
  Duration? receiveTimeout
  {
    get { return (Duration?)wrap |->Obj?| { return socket->getReceiveTimeout } }
    set { newVal := it; wrap |->| { socket->setReceiveTimeout(newVal) } }
  }

  **
  ** TCP_NODELAY socket option specifies that send not be delayed
  ** to merge packets (Nagle's algorthm).
  **
  Bool noDelay
  {
    get { return (Bool)wrap |->Obj| { return socket->getNoDelay } }
    set { newVal := it; wrap |->| { socket->setNoDelay(newVal) } }
  }

  **
  ** The type-of-class byte in the IP packet header.
  **
  ** For IPv4 this value is detailed in RFC 1349 as the following bitset:
  **  - IPTOS_LOWCOST     (0x02)
  **  - IPTOS_RELIABILITY (0x04)
  **  - IPTOS_THROUGHPUT  (0x08)
  **  - IPTOS_LOWDELAY    (0x10)
  **
  ** For IPv6 this is the value placed into the sin6_flowinfo header field.
  **
  Int trafficClass
  {
    get { return (Int)wrap |->Obj| { return socket->getTrafficClass } }
    set { newVal := it; wrap |->| { socket->setTrafficClass(newVal) } }
  }

//////////////////////////////////////////////////////////////////////////
// Wrap
//////////////////////////////////////////////////////////////////////////

  internal Obj? wrap(|->Obj?| m)
  {
    try
    {
      return m()
    }
    catch (UnknownSlotErr e)
    {
      throw UnsupportedErr("Option not supported for ${Type.of(socket)}")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Obj socket

}