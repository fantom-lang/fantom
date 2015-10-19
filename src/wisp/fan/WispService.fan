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
** Simple web server services HTTP/HTTPS requests to a top-level root WebMod.
** A given instance of WispService can be only be used through one
** start/stop lifecycle.
**
** Example:
**   WispService { httpPort = 8080; root = MyWebMod() }.start
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

  @NoDoc @Deprecated { msg = "Use httpPort" }
  const Int port := 0

  **
  ** Well known TCP port for HTTP traffic. The port is enabled if non-null
  ** and disabled if null.
  **
  const Int? httpPort := null

  **
  ** Well known TCP port for HTTPS traffic. The port is enabled if non-null
  ** and disabled if null. If the http and https ports are both non-null
  ** then all http traffic will be redirected to the https port.
  **
  const Int? httpsPort := null

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

  private static WebMod initErrMod()
  {
    try
      return (WebMod)Type.find(Pod.find("web").config("errMod", "wisp::WispDefaultErrMod")).make
    catch (Err e)
      log.err("Cannot init errMod", e)
    return WispDefaultErrMod()
  }

  **
  ** Map of HTTP headers to include in every response.  These are
  ** initialized from etc/web/config.props with the key "extraResHeaders"
  ** as a set of "key:value" pairs separated by semicolons.
  **
  const Str:Str extraResHeaders := initExtraResHeaders

  private static Str:Str initExtraResHeaders()
  {
    acc := Str:Str[:] { caseInsensitive = true }
    try
    {
      Pod.find("web").config("extraResHeaders", "").split(';').each |pair|
      {
        if (pair.isEmpty) return
        colon := pair.index(":") ?: throw Err("Missing colon: $pair")
        key := pair[0..<colon].trim
        val := pair[colon+1..-1].trim
        if (key.isEmpty || val.isEmpty) throw Err("Invalid header: $pair")
        acc[key] = val
      }
    }
    catch (Err e) log.err("Cannot init resHeaders", e)
    return acc.toImmutable
  }

  **
  ** Constructor with it-block
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)

    if (httpPort == null && port > 0) httpPort = port
    if (httpPort == null && httpsPort == null) throw ArgErr("httpPort and httpsPort are both null. At least one port must be configured.")
    if (httpPort == httpsPort) throw ArgErr("httpPort '${httpPort}' cannot be the same as httpsPort '${httpsPort}'")
    if (httpPort != null && httpsPort != null) root = WispHttpsRedirectMod(this, root)

    listenerPool     = ActorPool { it.name = "WispServiceListener" }
    httpListenerRef  = AtomicRef()
    httpsListenerRef = AtomicRef()
    processorPool    = ActorPool { it.name = "WispService"; it.maxThreads = this.maxThreads }
  }

  override Void onStart()
  {
    if (listenerPool.isStopped) throw Err("WispService is already stopped, use to new instance to restart")
    if (httpPort != null)
      Actor(listenerPool, |->| { listen(makeListener, httpPort) }).send(null)
    if (httpsPort != null)
      Actor(listenerPool, |->| { listen(makeListener(true), httpsPort) }).send(null)
    sessionStore.onStart
    root.onStart
  }

  override Void onStop()
  {
    try root.onStop;         catch (Err e) log.err("WispService stop root WebMod", e)
    try listenerPool.stop;   catch (Err e) log.err("WispService stop listener pool", e)
    try closeListener(httpListenerRef);  catch (Err e) log.err("WispService stop http listener socket", e)
    try closeListener(httpsListenerRef); catch (Err e) log.err("WispService stop https listener socket", e)
    try processorPool.stop;  catch (Err e) log.err("WispService stop processor pool", e)
    try sessionStore.onStop; catch (Err e) log.err("WispService stop session store", e)
  }

  private Void closeListener(AtomicRef listenerRef)
  {
    listenerRef.val?->val?->close
  }

  internal Void listen(TcpListener listener, Int port)
  {
    portType := port == httpPort ? "http" : "https"
    // loop until we successfully bind to port
    while (true)
    {
      try
      {
        listener.bind(addr, port)
        break
      }
      catch (Err e)
      {
        log.err("WispService cannot bind to ${portType} port ${port}", e)
        Actor.sleep(10sec)
      }
    }
    log.info("${portType} started on port ${port}")

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
          log.err("WispService accept on ${portType} port ${port}", e)
          Actor.sleep(5sec)
        }
      }
    }

    // socket should be closed by onStop, but do it again to be really sure
    try { listener.close } catch {}
    log.info("${portType} stopped on port ${port}")
  }

  private TcpListener makeListener(Bool secure := false)
  {
    try
    {
      AtomicRef ref := httpListenerRef
      TcpListener listener := TcpListener()
      if (secure)
      {
        ref = httpsListenerRef
        listener = TcpListener.makeTls
      }
      ref.val = Unsafe(listener)
      return listener
    }
    catch (Err e)
    {
      log.err("Could not make listener", e)
      throw e
    }
  }

  internal const ActorPool listenerPool
  internal const AtomicRef httpListenerRef
  internal const AtomicRef httpsListenerRef
  internal const ActorPool processorPool

  @NoDoc static Void main()
  {
    WispService { httpPort = 8080 }.start
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
** WispHttpsRedirectMod
**************************************************************************

**
** Redirects all http traffic to https
**
internal const class WispHttpsRedirectMod : WebMod
{
  new make(WispService service, WebMod root)
  {
    this.service = service
    this.root = root
  }

  override Void onService()
  {
    if (req.socket.localPort == service.httpPort)
    {
      redirectUri := `https://${req.absUri.host}:${service.httpsPort}${req.uri}`
      res.redirect(redirectUri)
    }
    else
    {
      root.onService
    }
  }

  const WispService service
  const WebMod root
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
