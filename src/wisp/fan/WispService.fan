//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//

using concurrent
using web
using inet

**
** Simple web server services HTTP requests on a configured port
** to a top-level root WebMod.  A given instance of WispService can
** be only be used through one start/stop lifecycle.
**
** Example:
**   WispService { port = 8080; root = MyWebMod() }.start
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

  **
  ** Pluggable interface for managing web session state.
  ** Default implementation stores sessions in main memory.
  **
  const WispSessionStore sessionStore := MemWispSessionStore()

  new make(|This|? f := null) { if (f != null) f(this) }

  override Void onStart()
  {
    if (listenerPool.isStopped) throw Err("WispService is already stopped, use to new instance to restart")
    Actor(listenerPool, |->| { listen }).send(null)
    sessionStore.onStart
    root.onStart
  }

  override Void onStop()
  {
    try root.onStop;            catch (Err e) log.err("WispService stop root WebMod", e)
    try tcpListener.val->close; catch (Err e) log.err("WispService stop listener socket", e)
    try listenerPool.stop;      catch (Err e) log.err("WispService stop listener pool", e)
    try processorPool.stop;     catch (Err e) log.err("WispService stop processor pool", e)
    try sessionStore.onStop;    catch (Err e) log.err("WispService stop session store", e)
  }

  internal Void listen()
  {
    // loop until we successfully bind to port
    listener := TcpListener()
    this.tcpListener.val = listener
    while (true)
    {
      try
      {
        listener.bind(null, port)
        break
      }
      catch (Err e)
      {
        log.err("WispService cannot bind to port ${port}", e)
        Actor.sleep(10sec)
      }
    }
    log.info("WispService started on port ${port}")

    // loop until stopped accepting incoming TCP connections
    while (!listenerPool.isStopped)
    {
      try
      {
        socket := listener.accept
        WispActor(this, socket).send(null)
      }
      catch (Err e)
      {
        if (!listenerPool.isStopped)
          log.err("WispService accept on ${port}", e)
      }
    }

    // socket should be closed by onStop, but do it again to be really sure
    try { listener.close } catch {}
    log.info("WispService stopped on port ${port}")
  }

  internal const ActorPool listenerPool    := ActorPool()
  internal const AtomicRef tcpListener     := AtomicRef()
  internal const ActorPool processorPool   := ActorPool()

  @NoDoc static Void main()
  {
    WispService { port = 8080 }.start
    Actor.sleep(Duration.maxVal)
  }
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