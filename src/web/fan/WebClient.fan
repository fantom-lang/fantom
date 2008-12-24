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
  ** Input stream to read response content.  The input stream
  ** will correctly handle end of stream when the content has been
  ** fully read.  If the "Content-Length" header was specified the
  ** end of stream is based on the fixed number of bytes.  If the
  ** "Transfer-Encoding" header defines a chunked encoding, then
  ** chunks are automatically handled.  If the response has no
  ** content body, then throw IOErr.
  **
  ** The response input stream is automatically configured with
  ** the correct character encoding if one is specified in the
  ** "Content-Type" response header.
  **
  InStream resIn()
  {
    if (resInStream == null) throw IOErr("No input stream for response $resCode")
    return resInStream
  }

  **
  ** Return the entire response back as an in-memory string.
  ** Convenience for 'resIn.readAllStr'.
  **
  Str resStr()
  {
    return resIn.readAllStr
  }

  **
  ** Return the entire response back as an in-memory byte buffer.
  ** Convenience for 'resIn.readAllBuf'.
  **
  Buf resBuf()
  {
    return resIn.readAllBuf
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

    // if there is response content, then create wrap the raw socket
    // input stream with the appropiate chunked input stream
    resInStream = wrapInStream

    // if we have a response content, then configure the char encoding
    if (resInStream != null) resInStream.charset = configContentEncoding

    return this
  }

  **
  ** Attempt to map the response headers to the appropiate type
  ** of wrapper around the raw socket input stream.
  **
  private InStream? wrapInStream()
  {
    // check for fixed content length
    len := resHeaders["Content-Length"]
    if (len != null)
      return ChunkInStream(socket.in, len.toInt)

    // check for chunked transfer encoding
    if (resHeaders.get("Transfer-Encoding", "").lower.contains("chunked"))
      return ChunkInStream(socket.in)

    // no content in response
    return null
  }

  **
  ** Map the "Content-Type" response header to the
  ** appropiate charset or default to UTF-8.
  **
  private Charset configContentEncoding()
  {
    ct := resHeaders["Content-Type"]
    if (ct != null)
    {
      cs := MimeType(ct).params["charset"]
      if (cs != null) return Charset(cs)
    }
    return Charset.utf8
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
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const Version ver10 := Version("1.0")
  private static const Version ver11 := Version("1.1")
  private static const Str:Str noHeaders := Str:Str[:]

  private InStream? resInStream

}