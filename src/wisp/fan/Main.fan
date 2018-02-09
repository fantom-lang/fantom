//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

using util
using inet

internal class Main : AbstractMain
{
  @Arg { help = "qualified type name for WebMod to run" }
  Str? mod

  @Opt { help = "IP address to bind to" }
  Str? addr

  @Opt { help = "IP port to bind for HTTP (default 8080)" }
  Int? httpPort := null

  @Opt { help = "IP port to bind for HTTPS (disabled unless set)" }
  Int? httpsPort := null

  override Int run()
  {
    runServices([WispService
    {
      it.addr = this.addr == null ? null : IpAddr(this.addr)
      it.httpPort = this.httpPort ?: 8080
      it.httpsPort = this.httpsPort
      it.root = Type.find(this.mod).make
    }])
  }
}

