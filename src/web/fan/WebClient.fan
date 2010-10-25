//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 08  Brian Frank  Almost Christmas!
//

using inet

**
** The 'WebClient' class is used to manage client side HTTP requests
** and responses.  The basic lifecycle of WebClient:
**   1. configure request fields such as 'reqUri', 'reqMethod', and 'reqHeaders'
**   2. send request headers via 'writeReq'
**   3. optionally write request body via 'reqOut'
**   4. read response status and headers via 'readRes'
**   5. process response fields such as 'resCode' and 'resHeaders'
**   6. optionally read response body via 'resIn'
**
** Using the low level methods 'writeReq' and 'readRes' enables HTTP
** pipelining (multiple requests and responses on the same TCP socket
** connection).  There are also a series of convenience methods which
** make common cases easier.
**
** See [pod doc]`pod-doc#webClient` and [examples]`examples::web-client`.
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
    set { if (!it.isAbs) throw ArgErr("Request URI not absolute: `$it`"); &reqUri = it }
  }

  **
  ** The HTTP method for the request.  Defaults to "GET".
  **
  Str reqMethod := "GET" { set { &reqMethod = it.upper } }

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

  **
  ** Get the output stream used to write the request body.  This
  ** stream is only available if the request headers included a
  ** "Content-Type" header.  If an explicit "Content-Length" was
  ** specified then this is a fixed length output stream, otherwise
  ** the request is automatically configured to use a chunked
  ** transfer encoding.  This stream should be closed once the
  ** content has been fully written.
  **
  OutStream reqOut()
  {
    if (reqOutStream == null) throw IOErr("No output stream for request")
    return reqOutStream
  }

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
  ** Also see convenience methods: `resStr` and `resBuf`.
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
  SocketOptions socketOptions()
  {
    if (options == null) options = TcpSocket().options
    return options
  }

  **
  ** When set to true a 3xx response with a Location header
  ** will automatically update the `reqUri` field and retry the
  ** request using the alternate URI.  Redirects are not followed
  ** if the request has a content body.
  **
  Bool followRedirects := true

//////////////////////////////////////////////////////////////////////////
// Get
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a GET request and return the response content as
  ** an in-memory string.  The web client is automatically closed.
  ** Throw IOErr is response is not 200.
  **
  Str getStr()
  {
    try
      return getIn.readAllStr
    finally
      close
  }

  **
  ** Make a GET request and return the response content as
  ** an in-memory byte buffer.  The web client is automatically closed.
  ** Throw IOErr is response is not 200.
  **
  Buf getBuf()
  {
    try
      return getIn.readAllBuf
    finally
      close
  }

  **
  ** Make a GET request and return the input stream to the
  ** response or throw IOErr if response is not 200.  It is the
  ** caller's responsibility to close this web client.
  **
  InStream getIn()
  {
    reqMethod = "GET"
    writeReq
    readRes
    if (resCode != 200) throw IOErr("Bad HTTP response $resCode $resPhrase")
    return resIn
  }

//////////////////////////////////////////////////////////////////////////
// Post
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a post request to the URI with the given form data.
  ** Set the Content-Type to application/x-www-form-urlencoded.
  ** Upon completion the response is ready to be read.
  **
  This postForm(Str:Str form)
  {
    body := Uri.encodeQuery(form)
    reqMethod = "POST"
    reqHeaders["Content-Type"] = "application/x-www-form-urlencoded"
    reqHeaders["Content-Length"] = body.size.toStr // encoded form is ASCII
    writeReq
    reqOut.print(body).close
    readRes
    return this
  }

  **
  ** Make a post request to the URI using UTF-8 encoding of given
  ** string.  If Content-Type is not already set, then set it
  ** to "text/plain; charset=utf-8".  Upon completion the response
  ** is ready to be read.
  **
  This postStr(Str content)
  {
    body := Buf().print(content).flip
    reqMethod = "POST"
    ct := reqHeaders["Content-Type"]
    if (ct == null)
      reqHeaders["Content-Type"] = "text/plain; charset=utf-8"
    reqHeaders["Content-Length"] = body.size.toStr
    writeReq
    reqOut.writeBuf(body).close
    readRes
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the request line and request headers.  Once this method
  ** completes the request body may be written via `reqOut`, or the
  ** response may be immediately read via `readRes`.  Throw IOErr
  ** if there is a network or protocol error.  Return this.
  **
  This writeReq()
  {
    // sanity checks
    if (!reqUri.isAbs || reqUri.scheme == null || reqUri.host == null) throw Err("reqUri is not absolute: `$reqUri`")
    if (!reqHeaders.caseInsensitive) throw Err("reqHeaders must be case insensitive")
    if (reqHeaders.containsKey("Host")) throw Err("reqHeaders must not define 'Host'")

    // connect to the host:port if we aren't already connected
    if (!isConnected)
    {
      socket = TcpSocket()
      if (options != null) socket.options.copyFrom(this.options)
      socket.connect(IpAddr(reqUri.host), reqUri.port ?: 80)
    }

    // figure out if/how we are streaming out content body
    out := socket.out
    reqOutStream = WebUtil.makeContentOutStream(reqHeaders, out)

    // host authority header
    host := reqUri.host
    if (reqUri.port != null && reqUri.port != 80) host += ":$reqUri.port"

    // send request
    out.print(reqMethod).print(" ").print(reqUri.relToAuth.encode)
       .print(" HTTP/").print(reqVersion).print("\r\n")
    out.print("Host: ").print(host).print("\r\n")
    reqHeaders.each |Str v, Str k| { out.print(k).print(": ").print(v).print("\r\n") }
    out.print("\r\n")
    out.flush

    return this
  }

  **
  ** Read the response status line and response headers.  This method
  ** may be called after the request has been written via `writeReq`
  ** and `reqOut`.  Once this method completes the response status and
  ** headers are available.  If there is a response body, it is available
  ** for reading via `resIn`.  Throw IOErr if there is a network or
  ** protocol error.  Return this.
  **
  This readRes()
  {
    // read response
    if (!isConnected) throw IOErr("Not connected")
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

    // check for redirect
    checkFollowRedirect

    // if there is response content, then create wrap the raw socket
    // input stream with the appropiate chunked input stream
    resInStream = WebUtil.makeContentInStream(resHeaders, socket.in)

    return this
  }

  **
  ** If we have a 3xx statu code with a location header,
  ** then check for an automate redirect.
  **
  private Void checkFollowRedirect()
  {
    // only redirect on 3xx status code
    if (resCode / 100 != 3) return

    // must be explicitly configured for redirects
    if (!followRedirects) return

    // only redirect when there is no request content
    if (reqOutStream != null) return

    // only redirect if a location header was given
    loc := resHeaders["Location"]
    if (loc == null) return

    // redirect
    close
    newUri := Uri.decode(loc)
    if (!newUri.isAbs) newUri = reqUri + newUri
    reqUri = newUri
    writeReq
    readRes
  }

  **
  ** Return if this web client is currently connected to the remote host.
  **
  Bool isConnected()
  {
    return socket != null && socket.isConnected
  }

  **
  ** Close the HTTP request and the underlying socket.  Return this.
  **
  This close()
  {
    if (socket != null) socket.close
    socket = null
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const Version ver10 := Version("1.0")
  private static const Version ver11 := Version("1.1")
  private static const Str:Str noHeaders := Str:Str[:]

  private InStream? resInStream
  private OutStream? reqOutStream
  private SocketOptions? options
  private TcpSocket? socket

}