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
  override Str:Obj stash := Str:Obj[:]
  override InStream in

  override Uri absUri
  {
    get
    {
      if (@absUri == null)
      {
        host := headers["Host"]
        if (host == null) throw Err("Missing Host header")
        @absUri = ("http://" + host + "/").toUri + uri
      }
      return @absUri
    }
  }

  override UserAgent userAgent
  {
    get
    {
      try
      {
        if (@userAgent == null)
        {
          header := headers["User-Agent"]
          if (header != null)
            @userAgent = UserAgent.fromStr(header)
        }
      }
      catch (Err e)
      {
        e.trace
      }
      return @userAgent
    }
  }

  override Str:Str cookies
  {
    get
    {
      try
      {
        if (@cookies == null)
        {
          @cookies = Str:Str[:]
          header := headers["Cookie"]
          if (header != null)
          {
            header.split(';', false).each |Str s|
            {
              if (s[0] == '$') return
              c := Cookie.fromStr(s)
              @cookies[c.name] = c.value
            }
          }
          @cookies = @cookies.ro
        }
      }
      catch (Err e)
      {
        e.trace
      }
      return @cookies
    }
  }

  override Str:Str form
  {
    get
    {
      if (@form == null && headers.get("Content-Type", "").startsWith("application/x-www-form-urlencoded"))
      {
        len := headers["Content-Length"]
        if (len == null) throw IOErr("Missing Content-Length header")
        @form = Uri.decodeQuery(in.readLine(len.toInt))
      }
      return @form
    }
  }
}