//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 07  Brian Frank  Creation
//

using concurrent
using inet
using web

**
** WispActor
**
internal const class WispActor : Actor
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(WispService service)
    : super(service.processorPool)
  {
    this.service = service
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Process a series of HTTP requests and responses on a socket.
  **
  override Obj? receive(Obj? msg)
  {
    process(((Unsafe)msg).val)
    return null
  }

  **
  ** Process a single HTTP request/response.
  **
  private Void process(TcpSocket socket)
  {
    WispRes? res
    WispReq? req
    close := true
    init := false

    try
    {
      // allocate request, response
      res = WispRes(service, socket)
      req = WispReq(service, socket, res)

      // init thread locals
      Actor.locals["web.req"] = req
      Actor.locals["web.res"] = res

      // before we do anything set a tight receive timeout in case
      // the client fails to send us data in a timely fashion
      socket.options.receiveTimeout = 10sec

      // parse request line and headers, on error terminate processing
      if (!parseReq(req)) return

      // initialize the req and res
      initReqRes(req, res)
      init = true

      // service the request which runs thru the installed web steps
      service.root.onService

      // save session if accessed
      service.sessionStore.doSave

      // on upgraded to new protocol then do not close socket;
      // otherwise ensure response if committed and flushed
       if (res.upgraded)
         close = false
       else
         res.close
    }
    catch (Err e)
    {
      if (init)
        internalServerErr(req, res, e)
      else
        e.trace
    }
    finally
    {
      Actor.locals.remove("web.req")
      Actor.locals.remove("web.res")
      if (close) try { socket.close } catch {}
    }
  }

//////////////////////////////////////////////////////////////////////////
// Request
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the first request line and request headers.
  ** Return true on success, false on failure.
  **
  internal static Bool parseReq(WispReq req)
  {
    try
    {
      // skip leading CRLF (4.1)
      in := req.socket.in
      line := in.readLine
      if (line == null) throw Err("Empty request line")
      while (line.isEmpty)
      {
        line = in.readLine
        if (line == null) throw Err("Empty request line")
      }

      // parse request-line (5.1)
      toks   := line.split
      method := toks[0]
      uri    := toks[1]
      ver    := toks[2]

      // method
      req.setMethod(method)

      // uri; immediately reject any uri which looks dangerous
      req.uri = Uri.decode(uri)
      if (req.uri.path.first == "..") throw Err("Reject URI")
      if (req.uri.pathStr.contains("//")) throw Err("Reject URI")

      // version
      if (ver == "HTTP/1.1") req.version = ver11
      else if (ver == "HTTP/1.0") req.version = ver10
      else throw Err("Unsupported version")

      // parse headers
      req.headers = WebUtil.parseHeaders(in).ro

      // success
      return true
    }
    catch (Err e)
    {
      // attempt to return error response
      try
      {
        out := req.socket.out
        req.socket.out
          .print("HTTP/1.1 400 Bad Request: $e.toStr.toCode\r\n")
          .print("\r\n").flush
      }
      catch (Err e2) {}
      return false
    }
  }

//////////////////////////////////////////////////////////////////////////
// Response
//////////////////////////////////////////////////////////////////////////

  **
  ** Initialize the request and response.
  **
  private Void initReqRes(WispReq req, WispRes res)
  {
    // init request input stream to read content
    req.webIn = initReqInStream(req)

    // configure Locale.cur for best match based on request
    Locale.setCur(req.locales.first)
  }

  **
  ** Map the raw HTTP input stream to handle the charset and transfer encoding
  **
  private InStream? initReqInStream(WispReq req)
  {
    // raw socket input stream
    raw := req.socket.in

    // if requesting an upgrade, then leave access to raw socket
    if (req.isUpgrade) return raw

    // init request - create content input stream wrapper
    wrap := WebUtil.makeContentInStream(req.headers, raw)

    // if the WebUtil didn't wrap the stream, then that means no
    // Content-Length or Transfer-Encoding - which in turn means we don't
    // consider this a valid request for sending a body in the request
    // according to 4.4 (since pipeling would be undefined)
    if (wrap === raw) return null
    return wrap
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  **
  ** Send back 500 Internal server error.
  **
  private Void internalServerErr(WispReq req, WispRes res, Err err)
  {
    try
    {
      // if the error is that the socket has been disconnected
      // by the remote side, then this isn't *my* error so we don't
      // want to log spurious socket errors; we can detect
      // this by attempting to flush the socket
      if (err is IOErr)
      {
        try { req.socket.out.flush } catch { return }
      }

      // log internal error
      if (!err.msg.contains("Broken pipe"))
        WispService.log.err("Internal error processing: $req.uri", err)

      // if not committed yet, then return 400 if bad
      // client request or 500 if server error
      if (!res.isCommitted)
      {
        res.statusCode = 500
        res.headers.clear
        req.stash["err"] = err
        service.errMod.onService
        res.close
      }
    }
    catch (Err e) WispService.log.err("internalServiceError res failed", e)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static const Version ver10 := Version("1.0")
  static const Version ver11 := Version("1.1")
  static const Str wispVer   := "Wisp/" + WispActor#.pod.version

  const WispService service
}