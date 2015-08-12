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
internal class WispReq : WebReq
{
  new make(WispService service, TcpSocket socket, WispRes res)
  {
    this.service = service
    this.socket  = socket
    this.res     = res
  }

  override WebMod mod := WispDefaultRootMod()
  override Str method := ""
  override Version version := nullVersion
  override IpAddr remoteAddr() { return socket.remoteAddr }
  override Int remotePort() { return socket.remotePort }
  override Str:Str headers := nullHeaders
  override Uri uri := ``
  override once WebSession session() { service.sessionStore.doLoad(this) }

  override InStream in()
  {
    if (webIn == null) throw Err("Attempt to access WebReq.in with no content")
    if (checkContinue)
    {
      checkContinue = false
      if (headers["Expect"]?.lower == "100-continue")
        res.sendContinue
    }
    return webIn
  }

  override SocketOptions socketOptions() { socket.options }
  override TcpSocket socket

  static const Version nullVersion := Version("0")
  static const Str:Str nullHeaders := Str:Str[:]

  internal WispService service
  internal InStream? webIn
  private Bool checkContinue := true
  private WispRes res

  internal Bool isUpgrade() { headers["Upgrade"] != null }
  internal Bool isKeepAlive() { headers.get("Connection", "").indexIgnoreCase("keep-alive") != null }

}