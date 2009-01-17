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
    this.socket        = socket
  }

  new makeTest(InStream in)
  {
    this.webIn = in
  }

  override WispService service
  override Str method
  override Version version
  override IpAddress remoteAddress() { return socket.remoteAddress }
  override Int remotePort() { return socket.remotePort }
  override Str:Str headers
  override Uri uri

  override InStream in()
  {
    if (webIn == null) throw Err("Attempt to access WebReq.in with no content")
    return webIn
  }

  internal TcpSocket socket
  internal InStream? webIn
}