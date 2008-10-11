//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** UdpPacket encapsulates an IpAddress, port, and payload of bytes
** to send or receive from a UdpSocket.
**
class UdpPacket
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a new UdpPacket.
  **
  new make(IpAddress? addr := null, Int? port := null, Buf? data := null)
  {
    this.address = addr
    this.port = port
    this.data = data
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** The send or receive IpAddress.  Defaults to null.
  **
  IpAddress? address := null

  **
  ** The send or receive port number.  Defaults to null.
  **
  Int? port := null

  **
  ** The payload to send or received.  Defaults to null.
  ** The data buffer must always be a memory backed buffer.
  **
  Buf? data := null

}