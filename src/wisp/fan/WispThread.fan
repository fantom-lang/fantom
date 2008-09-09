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
  ** Process a HTTP request and response.
  **
  override Obj run()
  {
    try
    {
      // before we do anything set a receive timeout in case
      // the client fails to send us data in a timely fashion
      socket.options.receiveTimeout = 10sec

      // make request, response
      req := WispReq(service, socket)
      res := WispRes(service, socket)

      // process request
      try
      {
        parseReq(req)
        initRes(req, res)
        service.service(req, res)
      }
      catch (Err e)
      {
        internalServerErr(req, res, e)
      }

      try { res.out.flush } catch {}
      return null
    }
    finally
    {
      try { socket.close } catch {}
    }
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the first request line.
  **
  static Void parseReq(WispReq req)
  {
    parseReqLine(req)
    parseReqHeaders(req)
  }

  **
  ** Parse the first request line.
  **
  private static Void parseReqLine(WispReq req)
  {
    in := req.in

    // skip leading CRLF (4.1)
    while (in.peek == '\r')
      in.skip(2) // CRLF

    // parse request-line (5.1)
    method := in.readStrToken(64)
    in.read  // SP
    uri := in.readStrToken(512)
    in.read  // SP
    ver := in.readStrToken(16)
    in.read  // CR
    in.read  // LF

    // map into the WispReq data structures
    req.method = method.upper
    try { req.uri = Uri.decode(uri) } catch (Err e) { throw badReq("Invalid uri '$uri: $e") }
    if (!ver.startsWith("HTTP/")) throw badReq("Invalid HTTP version '$ver'")
    try { req.version = Version.fromStr(ver[5..-1]) } catch { throw badReq("Invalid HTTP version '$ver'") }

    // immediately reject any uri which starts with ..
    if (req.uri.path.first == "..") throw badReq("Invalid .. in URI: '$uri'")
  }

  **
  ** Parse the request headers according to (4.2)
  **
  private static Void parseReqHeaders(WispReq req)
  {
    try
    {
      req.headers = WebUtil.parseHeaders(req.in).ro
    }
    catch (Err e)
    {
      throw badReq("Invalid HTTP headers: $e")
    }
  }

  **
  ** Return an error during request parsing.
  **
  private static BadReqErr badReq(Str msg, Err cause := null)
  {
    return BadReqErr(msg, cause)
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
    res.headers["Connection"] = "Close"
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  **
  ** Process an internal error.
  **
  private Void internalServerErr(WebReq req, WebRes res, Err err)
  {
    // dump to standard out
    echo("ERROR: $req.uri")
    err.trace

    // if not committed yet, then return 400 if bad
    // client request or 500 if server error
    if (!res.isCommitted)
    {
      res.statusCode = err is BadReqErr ? 400 : 500
      res.headers.clear
      res.headers["Content-Type"] = "text/plain"
      res.out.print("ERROR: $req.uri\n")
      err.trace(res.out)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const WispService service
  const TcpSocket socket
}

** Used to indicate an error parsing the request
internal const class BadReqErr : Err
{
  new make(Str msg, Err cause := null) : super(msg, cause) {}
}