//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//

using web
using inet

**
** Wisp implementation of WebService.
**
const class WispService : Service
{

  **
  ** Standard log for web service
  **
  internal static const Log log := Log.get("web")

  **
  ** Well known TCP port for HTTP traffic.
  **
  const Int port := 80

  **
  ** Root WebMod used to service requests.
  **
  const WebMod root := WispDefaultMod()


  new make(|This|? f := null) { if (f != null) f(this) }

  override Void onStart()
  {
    Actor(listenerPool, |->| { listen }).send(null)
    root.onStart
  }

  override Void onStop()
  {
    root.onStop
    listenerPool.stop
    processorPool.stop
    sessionMgr.stop
  }

  internal Void listen()
  {
    listener := TcpListener()
    listener.bind(null, port)
    log.info("WispService started on port ${port}")

    while (!listenerPool.isStopped)
    {
      socket := listener.accept
      WispActor(this, socket).send(null)
    }
  }

  internal const ActorPool listenerPool   := ActorPool()
  internal const ActorPool processorPool  := ActorPool()
  internal const WispSessionMgr sessionMgr := WispSessionMgr()

}


internal const class WispDefaultMod : WebMod
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.html
      .head
        .title.w("Wisp").titleEnd
      .headEnd
      .body
        .h1.w("Wisp").h1End
        .p.w("Wisp is running!").pEnd
        .p.w("Currently there is no WebMod installed on this server.").pEnd
        .p.w("See <a href='http://fantom.org/doc/wisp/pod-doc.html'>wisp::pod-doc</a>
              to configure a WebMod for the server.").pEnd
      .bodyEnd
    .htmlEnd
  }
}