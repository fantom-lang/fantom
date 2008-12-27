//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 07  Brian Frank  Creation
//

using inet
using web

**
** WispReq
**
class WispReq : WebReq
{
  new make(WispService service, TcpSocket socket)
  {
    this.service       = service
    this.remoteAddress = socket.remoteAddress
    this.remotePort    = socket.remotePort
    this.in            = socket.in
  }

  new makeTest(InStream in)
  {
    this.in = in
  }

  override WispService service
  override Str method
  override Version version
  override IpAddress remoteAddress
  override Int remotePort
  override Str:Str headers
  override Uri uri
  override InStream in

}