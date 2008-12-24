//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 08  Brian Frank  Almost Christmas!
//

using inet

**
** WebClient manages client side HTTP requests.
**
class WebClient
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with optional request URI.
  **
  new make(Uri? reqUri := null)
  {
    if (reqUri != null) this.reqUri = reqUri
  }

//////////////////////////////////////////////////////////////////////////
// Request
//////////////////////////////////////////////////////////////////////////

  **
  ** The absolute URI of request.
  **
  Uri reqUri := ``
  {
    set { if (!val.isAbs) throw ArgErr("Request URI not absolute: `$val`"); @reqUri = val }
  }

  **
  ** The HTTP method for the request.  Defaults to "GET".
  **
  Str reqMethod := "GET"

  **
  ** HTTP version to use for request must be 1.0 or 1.1.
  ** Default is 1.1.
  **
  Version reqVersion := ver11

  **
  ** The HTTP headers to use for the next request.  This map uses
  ** case insensitive keys.  The "Host" header is implicitly defined
  ** by 'reqUri' and must not be defined in this map.
  **
  Str:Str reqHeaders := Str:Str[:] { caseInsensitive = true }

//////////////////////////////////////////////////////////////////////////
// Response
//////////////////////////////////////////////////////////////////////////

  **
  ** HTTP version returned by response.
  **
  Version resVersion := ver11

  **
  ** HTTP status code returned by response.
  **
  Int resCode

  **
  ** HTTP status reason phrase returned by response.
  **
  Str resPhrase := ""

  **
  ** HTTP headers returned by response.
  **
  Str:Str resHeaders := noHeaders

  **
  ** Get a response header.  If not found and checked
  ** is false then return true, otherwise throw Err.
  **
  Str? resHeader(Str key, Bool checked := true)
  {
    val := resHeaders[key]
    if (val != null || !checked) return val
    throw Err("Missing HTTP header '$key'")
  }

  **
  ** Input stream to read from
  **
  InStream resIn() { return socket.in }

  **
  ** Return the entire response back as an in-memory string.
  **
  Str resStr()
  {
    // TODO: char encoding, chunked streams
    in := socket.in
    len := resHeader("Content-Length").toInt
    str := StrBuf()
    len.times |,| { str.addChar(in.readChar) }
    return str.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Networking
//////////////////////////////////////////////////////////////////////////

  **
  ** Socket options for the TCP socket used for requests.
  **
  SocketOptions socketOptions() { return socket.options }

  **
  ** Socket used to service requests.
  **
  private TcpSocket socket := TcpSocket()

//////////////////////////////////////////////////////////////////////////
// Get
//////////////////////////////////////////////////////////////////////////

  **
  ** Open the HTTP request - TODO.  Throw IOErr if there is a network or
  ** protocol error.  Return this.
  **
  WebClient open()
  {
    // sanity checks
    if (!reqUri.isAbs) throw Err("reqUri is not absolute: `$reqUri`")
    if (!reqHeaders.caseInsensitive) throw Err("reqHeaders must be case insensitive")
    if (reqHeaders.containsKey("Host")) throw Err("reqHeaders must not define 'Host'")

    // connect to the host:port
    socket.connect(IpAddress(reqUri.host), reqUri.port ?: 80)

    // send request
    out := socket.out
    out.print(reqMethod).print(" ").print(reqUri.relToAuth.encode)
       .print(" HTTP/").print(reqVersion).print("\r\n")
    out.print("Host: ").print(reqUri.host).print("\r\n")
    reqHeaders.each |Str v, Str k| { out.print(k).print(": ").print(v).print("\r\n") }
    out.print("\r\n")
    out.flush

    // read response
    in := socket.in
    try
    {
      // parse status-line
      res := in.readLine
      if (res.startsWith("HTTP/1.1")) resVersion = ver11
      else if (res.startsWith("HTTP/1.0")) resVersion = ver10
      else throw Err()
      resCode = res[9..11].toInt
      resPhrase = res[13..-1]

      // parse response headers
      resHeaders = WebUtil.parseHeaders(in)
    }
    catch throw IOErr("Invalid HTTP response")

    return this
  }

  **
  ** Close the HTTP request and the underlying socket.  Return this.
  **
  This close()
  {
    socket.close
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  private static const Version ver10 := Version("1.0")
  private static const Version ver11 := Version("1.1")
  private static const Str:Str noHeaders := Str:Str[:]

}