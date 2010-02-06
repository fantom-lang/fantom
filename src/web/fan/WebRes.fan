//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 06  Andy Frank  Creation
//

**
** WebRes encapsulates a response to a web request.
**
** See [pod doc]`pod-doc#webRes`
**
abstract class WebRes
{

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Get or set the HTTP status code for this response. Status code
  ** defaults to 200.  Throw an err if status code passed in is not
  ** recognized, or if the response has already been committed.
  **
  abstract Int statusCode

  **
  ** Map of HTTP response headers.  You must set all headers before
  ** you access out() for the first time, which commits the response.
  ** Throw an err if response is already committed.
  **
  abstract Str:Str headers()

  **
  ** Get the list of cookies to set via header fields.  Add a
  ** a Cookie to this list to set a cookie.  Throw an err if
  ** response is already committed.
  **
  ** Example:
  **   res.cookies.add(Cookie("foo", "123"))
  **   res.cookies.add(Cookie("persistent", "some val") { maxAge = 3day })
  **
  abstract Cookie[] cookies()

  **
  ** Return true if this response has been commmited.  A committed
  ** response has written its response headers, and can no longer
  ** modify its status code or headers.  A response is committed
  ** the first time that `out` is called.
  **
  abstract Bool isCommitted()

  **
  ** Return the WebOutStream for this response.  The first time this
  ** method is accessed the response is committed: all headers
  ** currently set will be written to the stream, and can no longer
  ** be modified.  If the "Content-Length" header defines a fixed
  ** number of bytes, then attemps to write too many bytes will throw
  ** an IOErr.  If "Content-Length" is not defined, then a chunked
  ** transfer encoding is automatically used.
  **
  abstract WebOutStream out()

  **
  ** Send a redirect response to the client using the specified status
  ** code and url.  If this response has already been committed this
  ** method throws an Err.  This method implicitly calls `done`.
  **
  abstract Void redirect(Uri uri, Int statusCode := 303)

  **
  ** Send an error response to client using the specified status and
  ** HTML formatted message.  If this response has already been committed
  ** this method throws an Err.  If the server has a preconfigured page
  ** for this error code, it will trump the message passed in.
  ** This method implicitly calls `done`.
  **
  abstract Void sendErr(Int statusCode, Str? msg := null)

  **
  ** Return if this response is complete - see `done`.
  **
  abstract Bool isDone()

  **
  ** Done is called to indicate that that response is complete
  ** to terminate pipeline processing.
  **
  abstract Void done()

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

  **
  ** Map of HTTP status codes to status messages.
  **
  static const Int:Str statusMsg :=
  [
    // 100
    100: "Continue",
    101: "Switching Protocols",
    // 200
    200: "OK",
    201: "Created",
    202: "Accepted",
    203: "203 Non-Authoritative Information",
    204: "No Content",
    205: "Reset Content",
    206: "Partial Content",
    // 300
    300: "Multiple Choices",
    301: "Moved Permanently",
    302: "Found",
    303: "See Other",
    304: "Not Modified",
    305: "Use Proxy",
    307: "Temporary Redirect",
    // 400
    400: "Bad Request",
    401: "Unauthorized",
    402: "Payment Required",
    403: "Forbidden",
    404: "Not Found",
    405: "Method Not Allowed",
    406: "Not Acceptable",
    407: "Proxy Authentication Required",
    408: "Request Timeout",
    409: "Conflict",
    410: "Gone",
    411: "Length Required",
    412: "Precondition Failed",
    413: "Request Entity Too Large",
    414: "Request-URI Too Long",
    415: "Unsupported Media Type",
    416: "Requested Range Not Satisfiable",
    417: "Expectation Failed",
    // 500
    500: "Internal Server Error",
    501: "Not Implemented",
    502: "Bad Gateway",
    503: "Service Unavailable",
    504: "Gateway Timeout",
    505: "HTTP Version Not Supported"
  ]

}