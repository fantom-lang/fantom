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
** WispRes
**
class WispRes : WebRes
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(WispService service, TcpSocket socket)
  {
    this.service = service
    @out = WebOutStream(socket.out)
    headers.caseInsensitive = true
  }

//////////////////////////////////////////////////////////////////////////
// WebRes
//////////////////////////////////////////////////////////////////////////

  **
  ** WispService.
  **
  override WispService service

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
      if (statusMsg[val] == null) throw Err("Unknown status code: $val")
      @statusCode = val
    }
  }

  **
  ** Map of HTTP response headers.  You must set all headers before
  ** you access out() for the first time, which commits the response.
  ** After the response is commited this map becomes read only.
  **
  override Str:Str headers := Str:Str[:]
  {
    get { checkUncommitted; return @headers }
  }

  **
  ** Get the list of cookies to set via a header fields.  Add a
  ** a Cookie to this list to set a cookie.  Once the response
  ** is commited, this list becomes readonly.
  **
  override Cookie[] cookies := Cookie[,]
  {
    get { checkUncommitted; return @cookies }
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
  ** be modified.
  **
  override WebOutStream out
  {
    get
    {
      commit
      return @out
    }
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
    commit
    done
  }

  **
  ** Send an error response to client using the specified status and
  ** HTML formatted message.  If this response has already been committed
  ** this method throws an Err.  If the server has a preconfigured page
  ** for this error code, it will trump the message passed in.
  **
  override Void sendError(Int statusCode, Str? msg := null)
  {
    checkUncommitted
    this.statusCode = statusCode
    headers["Content-Type"] = "text/html"

    out.docType
    out.html
    out.head.title("$statusCode ${statusMsg[statusCode]}").headEnd
    out.body
    out.h1(statusMsg[statusCode])
    if (msg != null) out.w(msg).nl
    out.bodyEnd
    out.htmlEnd
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
  Void checkUncommitted()
  {
    if (isCommitted) throw Err("WebRes already committed")
  }

  **
  ** If we haven't committed yet, then write the response header.
  **
  Void commit()
  {
    if (isCommitted) return
    isCommitted = true
    @out.w("HTTP/1.1 ").w(statusCode).w(" ").w(statusMsg[statusCode]).w("\r\n")
    @headers.each |Str v, Str k| { @out.w(k).w(": ").w(v).w("\r\n") }
    @cookies.each |Cookie c| { @out.w("Set-Cookie: ").w(c).w("\r\n") }
    @out.w("\r\n")
  }

}