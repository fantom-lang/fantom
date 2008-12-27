//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jul 08  Brian Frank  Creation
//

using inet
using web

internal class TestWebReq : WebReq
{
  override WebService service
  override Str method
  override Version version
  override IpAddress remoteAddress
  override Int remotePort
  override Str:Str headers
  override Uri uri
  override InStream in
}

internal class TestWebRes : WebRes
{
  override WebService service
  override Int statusCode := 200
  override Str:Str headers := Str:Str[:]
  override Cookie[] cookies := Cookie[,]
  override readonly Bool isCommitted := false
  override WebOutStream out
  override Void redirect(Uri uri, Int sc := 303) { statusCode = sc }
  override Void sendError(Int sc, Str? msg := null) { statusCode = sc }
  override readonly Bool isDone := false
  override Void done() { isDone = true }
}