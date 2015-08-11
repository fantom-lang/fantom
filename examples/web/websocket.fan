#! /usr/bin/env fan
//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 15  Brian Frank  Creation
//

using util
using web
using wisp

**
** WebSocketDemo
** Run as server: websocket
** Run as client: websocket -c msg
** Another client: http://www.websocket.org/echo.html
**
class WebSocketDemo : AbstractMain
{
  @Opt { help = "http port" }
  Int httpPort := 8080

  @Opt { help = "client connection" }
  Str uri := "ws://localhost:8080/"

  @Opt { help = "message to send client" }
  Str? c

  override Int run()
  {
    if (c != null)
      return runClient
    else
      return runServer
  }

  Int runClient()
  {
    uri := this.uri.toUri
    echo("Connect: $uri")
    s := WebSocket.openClient(uri)
    echo("Connected!")
    echo("Send: $c")
    s.send(c)
    echo("Receiving...")
    res := s.receive
    echo("Received: $res")
    return 0
  }

  Int runServer()
  {
    wisp := WispService
    {
      it.httpPort = this.httpPort
      it.root = WebSocketMod()
    }
    return runServices([wisp])
  }
}

const class WebSocketMod : WebMod
{
  override Void onGet()
  {
    socket := WebSocket.openServer(req, res)
    echo("WebSocket.opened")
    while (true)
    {
      msg := socket.receive
      if (msg == null) break
      echo("WebSocket.received: $msg")
      socket.send("Echo: $msg")
    }
    echo("WebSocket.closed")
  }
}