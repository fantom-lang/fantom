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
** WispThread
**
internal const class WispThread : Thread
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(WispService service, TcpSocket socket)
    : super()
  {
    this.service = service
    this.socket  = socket
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Process a series of HTTP request and response on a socket.
  **
  override Obj? run()
  {
    try
    {
      // before we do anything set a receive timeout in case
      // the client fails to send us data in a timely fashion
      socket.options.receiveTimeout = 10sec

      // loop processing requests with on this socket as
      // long as a persistent connection is being used and
      // we don't have any errors
      while (process) {}
    }
    catch (Err e) { e.trace }
    finally { try { socket.close } catch {} }
    return null
  }

  **
  ** Process a single HTTP request/response.  Return true if the request
  ** was processed successfully and that a persistent connection is being
  ** used. Return false on error or if the socket should be shutdown.
  **
  Bool process()
  {
    // allocate request, response
    req := WispReq(service, socket)
    res := WispRes(service, socket)

    // parse request line
    if (!parseReqLine(req)) return badReqErr

    // parse headers
    if (!parseReqHeaders(req)) return badReqErr

    // service request
    success := false
    try
    {
      initRes(req, res)
      service.service(req, res)
      success = true
    }
    catch (Err e)
    {
      internalServerErr(req, res, e)
    }

    // ensure response is committed and close the response
    // output stream, but don't close the underlying socket
    try { res.close } catch (Err e) { e.trace }

    // return if using persistent connections
    return success && isPersistent(req)
  }

  **
  ** Return if the request indicates use of persistent connections.
  ** If using 1.0 or if the connection header is not "close" then we
  ** assume persistent connections.
  **
  Bool isPersistent(WispReq req)
  {
    return req.headers.get("Connection", "").lower != "close" ||
           req.version.minor == 0
  }

//////////////////////////////////////////////////////////////////////////
// Request
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the first request line.
  ** Return true on success, false on failure.
  **
  internal static Bool parseReqLine(WispReq req)
  {
    try
    {
      // skip leading CRLF (4.1)
      line := req.in.readLine
      if (line == null) return false
      while (line.isEmpty)
      {
        line = req.in.readLine
        if (line == null) return false
      }

      // parse request-line (5.1)
      toks   := line.split
      method := toks[0]
      uri    := toks[1]
      ver    := toks[2]

      // method
      req.method = method.upper

      // uri; immediately reject any uri which starts with ..
      req.uri = Uri.decode(uri)
      if (req.uri.path.first == "..") return false

      // version
      if (ver == "HTTP/1.1") req.version = ver11
      else if (ver == "HTTP/1.0") req.version = ver10
      else return false

      // success
      return true
    }
    catch return false
  }

  **
  ** Parse the request headers according to (4.2)
  ** Return true on success, false on failure.
  **
  internal static Bool parseReqHeaders(WispReq req)
  {
    try
    {
      req.headers = WebUtil.parseHeaders(req.in).ro
      return true
    }
    catch return false
  }

//////////////////////////////////////////////////////////////////////////
// Response
//////////////////////////////////////////////////////////////////////////

  **
  ** Initialize a response with the predefined headers.
  **
  private Void initRes(WebReq req, WebRes res)
  {
    res.headers["Server"] = "Wisp/" + type.pod.version
    res.headers["Date"] = DateTime.now.toHttpStr
    res.headers["Connection"] = "keep-alive"
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  **
  ** Send back 400 bad request response.  Return false.
  **
  private Bool badReqErr()
  {
    try
    {
      socket.out.print("HTTP/1.1 400 Bad Request\r\n\r\n").flush
    }
    catch {}
    return false
  }

  **
  ** Send back 500 Internal server error.
  **
  private Void internalServerErr(WebReq req, WebRes res, Err err)
  {
    try
    {
      // log internal error
      WispService.log.error("Internal error processing: $req.uri", err)

      // if not committed yet, then return 400 if bad
      // client request or 500 if server error
      if (!res.isCommitted)
      {
        res.statusCode = 500
        res.headers.clear
        res.headers["Content-Type"] = "text/plain"
        res.out.print("ERROR: $req.uri\n")
        err.trace(res.out)
      }
    }
    catch (Err e) { e.trace }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static const Version ver10 := Version("1.0")
  static const Version ver11 := Version("1.1")

  const WispService service
  const TcpSocket socket
}