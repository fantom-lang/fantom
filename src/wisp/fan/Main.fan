//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

using util
using inet
using web

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

**************************************************************************
** TestMod
**************************************************************************

/*
internal const class TestMod : WebMod
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/plain"
    res.out.printLine("$req.method $req.uri")
    req.headers.each |v, n| { res.out.printLine("$n: $v") }
    res.out.flush
    num := ((TestOutStream)req.stash["testOut"]).num
    echo("-- $req.uri $num bytes")
  }

  override WebOutStream? makeResOut(OutStream out)
  {
    tout := TestOutStream(out)
    req.stash["testOut"] = tout
    return super.makeResOut(tout)
  }
}

internal class TestOutStream : OutStream
{
  new make(OutStream out) : super(out) {}
  Int num := 0
  override This write(Int byte) { super.write(byte); num++; return this }
  override This writeBuf(Buf buf, Int n := buf.remaining) { super.writeBuf(buf, n); num += n; return this }
}
*/




