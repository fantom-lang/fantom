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
  ** Which IpAddr to bind to or null for the default.
  **
  const IpAddr? addr := null

  **
  ** Well known TCP port for HTTP traffic.
  **
  const Int port := 80

  **
  ** Root WebMod used to service requests.
  **
  const WebMod root := WispDefaultRootMod()

  **
  ** Pluggable interface for managing web session state.
  ** Default implementation stores sessions in main memory.
  **
  const WispSessionStore sessionStore := MemWispSessionStore()

  **
  ** Max number of threads which are used for concurrent
  ** web request processing.
  **
  const Int maxThreads := 500

  **
  ** WebMod which is called on internal server error to return an 500
  ** error response.  The exception raised is available in 'req.stash["err"]'.
  ** The 'onService' method is called after clearing all headers and setting
  ** the response code to 500.  The default error mod may be configured
  ** via 'errMod' property in etc/web/config.props.
  **
  const WebMod errMod := initErrMod

  private WebMod initErrMod()
  {
    try
      return (WebMod)Type.find(Pod.find("web").config("errMod", "wisp::WispDefaultErrMod")).make
    catch (Err e)
      log.err("Cannot init errMod", e)
    return WispDefaultErrMod()
  }

  **
  ** Constructor with it-block
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    listenerPool   = ActorPool { it.name = "WispServiceListener" }
    tcpListenerRef = AtomicRef()
    processorPool  = ActorPool { it.name = "WispService"; it.maxThreads = this.maxThreads }
  }

  override Void onStart()
  {
    if (listenerPool.isStopped) throw Err("WispService is already stopped, use to new instance to restart")
    Actor(listenerPool, |->| { listen }).send(null)
    sessionStore.onStart
    root.onStart
  }

  override Void onStop()
  {
    try root.onStop;         catch (Err e) log.err("WispService stop root WebMod", e)
    try listenerPool.stop;   catch (Err e) log.err("WispService stop listener pool", e)
    try closeTcpListener;    catch (Err e) log.err("WispService stop listener socket", e)
    try processorPool.stop;  catch (Err e) log.err("WispService stop processor pool", e)
    try sessionStore.onStop; catch (Err e) log.err("WispService stop session store", e)
  }

  private Void closeTcpListener()
  {
    Unsafe unsafe := tcpListenerRef.val
    TcpListener listener := unsafe.val
    listener.close
  }

  internal Void listen()
  {
    // loop until we successfully bind to port
    listener := TcpListener()
    tcpListenerRef.val = Unsafe(listener)
    while (true)
    {
      try
      {
        listener.bind(addr, port)
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
    while (!listenerPool.isStopped && !listener.isClosed)
    {
      try
      {
        socket := listener.accept
        WispActor(this).send(Unsafe(socket))
      }
      catch (Err e)
      {
        if (!listenerPool.isStopped && !listener.isClosed)
        {
          log.err("WispService accept on ${port}", e)
          Actor.sleep(5sec)
        }
      }
    }

    // socket should be closed by onStop, but do it again to be really sure
    try { listener.close } catch {}
    log.info("WispService stopped on port ${port}")
  }

  internal const ActorPool listenerPool
  internal const AtomicRef tcpListenerRef
  internal const ActorPool processorPool

  @NoDoc static Void main()
  {
    WispService { port = 8080 }.start
    Actor.sleep(Duration.maxVal)
  }
}

**************************************************************************
** WispDefaultRootMod
**************************************************************************

internal const class WispDefaultRootMod : WebMod
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

**************************************************************************
** WispDefaultErrMod
**************************************************************************

const class WispDefaultErrMod : WebMod
{
  override Void onService()
  {
    err := (Err)req.stash["err"]
    res.headers["Content-Type"] = "text/plain"
    str := "ERROR: $req.uri\n$err.traceToStr".replace("<", "&gt;")
    res.out.print(str)
  }
}


