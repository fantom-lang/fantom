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
** WispRes
**
internal class WispRes : WebRes
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(WispService service, TcpSocket socket)
  {
    this.service = service
    this.socket  = socket
    headers.caseInsensitive = true
  }

//////////////////////////////////////////////////////////////////////////
// WebRes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get or set the HTTP status code for this response. Status code
  ** defaults to 200. If response has already been committed, throws Err.
  ** If status code passed in is not recognized, throws Err.
  **
  override Int statusCode := 200
  {
    set
    {
      checkUncommitted
      if (statusMsg[it] == null) throw Err("Unknown status code: $it");
      &statusCode = it
    }
  }

  **
  ** Map of HTTP response headers.  You must set all headers before
  ** you access out() for the first time, which commits the response.
  ** After the response is commited this map becomes read only.
  **
  override Str:Str headers := Str:Str[:]
  {
    get { checkUncommitted; return &headers }
  }

  **
  ** Get the list of cookies to set via a header fields.  Add a
  ** a Cookie to this list to set a cookie.  Once the response
  ** is commited, this list becomes readonly.
  **
  override Cookie[] cookies := Cookie[,]
  {
    get { checkUncommitted; return &cookies }
  }

  **
  ** Return true if this response has been commmited.  A committed
  ** response has written its response headers, and can no longer
  ** modify its status code or headers.  A response is committed the
  ** first time that `out` is called.
  **
  override readonly Bool isCommitted := false

  **
  ** Return the WebOutStream for this response.  The first time this
  ** method is accessed the response is committed: all headers
  ** currently set will be written to the stream, and can no longer
  ** be modified.  If the "Content-Length" header defines a fixed
  ** number of bytes, then attemps to write too many bytes will throw
  ** an IOErr.  If "Content-Length" is not defined, then a chunked
  ** transfer encoding is automatically used.
  **
  override WebOutStream out()
  {
    // if we are grabbing a stream to write response content, then
    // ensure we are committed with content; it is an illegal state
    // if another code path committed with no-content
    commit(true)
    if (webOut == null) throw Err("Must set Content-Length or Content-Type to write content")
    return webOut
  }

  **
  ** Send a redirect response to the client using the specified status
  ** code and url.  If this response has already been committed this
  ** method throws an Err.
  **
  override Void redirect(Uri uri, Int statusCode := 303)
  {
    checkUncommitted
    this.statusCode = statusCode
    headers["Location"] = uri.encode
    headers["Content-Length"] = "0"
    commit(false)
    done
  }

  **
  ** Send an error response to client using the specified status and
  ** HTML formatted message.  If this response has already been committed
  ** this method throws an Err.  If the server has a preconfigured page
  ** for this error code, it will trump the message passed in.
  **
  override Void sendErr(Int statusCode, Str? msg := null)
  {
    // write message to buffer
    buf := Buf()
    WebOutStream bufOut := WebOutStream(buf.out)
    bufOut.docType
    bufOut.html
    bufOut.head.title.w("$statusCode ${statusMsg[statusCode]}").titleEnd.headEnd
    bufOut.body
    bufOut.h1.w(statusMsg[statusCode]).h1End
    if (msg != null) bufOut.w(msg).nl
    bufOut.bodyEnd
    bufOut.htmlEnd

    // write response
    checkUncommitted
    this.statusCode = statusCode
    headers["Content-Type"] = "text/html; charset=UTF-8"
    headers["Content-Length"] = buf.size.toStr
    this.out.writeBuf(buf.flip)
    done
  }

  **
  ** Return if this response is complete - see `done`.
  **
  override readonly Bool isDone := false

  **
  ** Done is called to indicate that that response is complete
  ** to terminate pipeline processing.  Once called, no further
  ** WebSteps in the pipeline are executed.
  **
  override Void done() { isDone = true }

//////////////////////////////////////////////////////////////////////////
// Impl
//////////////////////////////////////////////////////////////////////////

  **
  ** If the response has already been committed, then throw an Err.
  **
  internal Void checkUncommitted()
  {
    if (isCommitted) throw Err("WebRes already committed")
  }

  **
  ** If we haven't committed yet, then write the response header.
  ** The content flag specifies whether this response will have a
  ** content body in the response.
  **
  internal Void commit(Bool content)
  {
    // check if committed
    if (isCommitted) return
    isCommitted = true

    // if we have content then we need to ensure we have our
    // headers and response stream are setup correctly
    sout := socket.out
    if (content)
    {
      // if using persistent connections we have to ensure out
      // socket stream is wrapped as either a FixedOutStream or
      // ChunkedOutStream so that close doesn't close the underlying
      // socket stream
      if (isPersistent)
      {
        cout := WebUtil.makeContentOutStream(&headers, sout)
        if (cout != null) webOut = WebOutStream(cout)
      }

      // if not using persistent connections, use raw socket stream
      else
      {
        webOut = WebOutStream(sout)
      }
    }

    // write response line and headers
    sout.print("HTTP/1.1 ").print(statusCode).print(" ").print(toStatusMsg).print("\r\n");
    &headers.each |Str v, Str k| { sout.print(k).print(": ").print(v).print("\r\n") };
    &cookies.each |Cookie c| { sout.print("Set-Cookie: ").print(c).print("\r\n") }
    sout.print("\r\n").flush
  }

  private Str toStatusMsg()
  {
    // special temp hook for WebSocket
    if (statusCode == 101 && &headers["Upgrade"] == "WebSocket")
      return "Web Socket Protocol Handshake"
    else
      return statusMsg[statusCode]
  }

  **
  ** This method is called to close down the response.  We ensure the
  ** response is committed and if we have a response output stream we
  ** close it to flush the content body.
  **
  internal Void close()
  {
    commit(false)
    if (webOut != null) webOut.close
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal WispService service
  internal TcpSocket socket
  internal WebOutStream? webOut
  internal Bool isPersistent

}