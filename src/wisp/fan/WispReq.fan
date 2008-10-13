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
  override Str:Obj? stash := Str:Obj?[:]
  override InStream in

  override once Uri absUri()
  {
    host := headers["Host"]
    if (host == null) throw Err("Missing Host header")
    return ("http://" + host + "/").toUri + uri
  }

  override once UserAgent? userAgent()
  {
    try
    {
      header := headers["User-Agent"]
      if (header != null)
        return UserAgent.fromStr(header)
    }
    catch (Err e)
    {
      e.trace
    }
    return null
  }

  override once Str:Str cookies()
  {
    cookies := Str:Str[:]
    try
    {
      header := headers["Cookie"]
      if (header != null)
      {
        header.split(';', false).each |Str s|
        {
          if (s[0] == '$') return
          c := Cookie.fromStr(s)
          cookies[c.name] = c.value
        }
      }
    }
    catch (Err e)
    {
      e.trace
    }
    return cookies.ro
  }

  override once [Str:Str]? form()
  {
    if (headers.get("Content-Type", "").startsWith("application/x-www-form-urlencoded"))
    {
      len := headers["Content-Length"]
      if (len == null) throw IOErr("Missing Content-Length header")
      return Uri.decodeQuery(in.readLine(len.toInt))
    }
    return null
  }
}