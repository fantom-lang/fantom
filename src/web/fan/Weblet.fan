//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 06  Andy Frank  Creation
//

**
** Weblet services a web request.
**
** See [docLib::Web]`docLib::Web#weblet`
**
abstract class Weblet
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Default constructor.
  **
  new make()
  {
    req = (WebReq)Thread.locals["web.req"]
    res = (WebRes)Thread.locals["web.res"]
  }

//////////////////////////////////////////////////////////////////////////
// Request/Response
//////////////////////////////////////////////////////////////////////////

  **
  ** The WebReq instance for this request.
  **
  @transient readonly WebReq req

  **
  ** The WebRes instance for this request.
  **
  @transient readonly WebRes res

//////////////////////////////////////////////////////////////////////////
// Service Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Service a web request. The default implementation of this
  ** method calls the method that matches WebReq.method.
  **
  virtual Void service()
  {
    switch (req.method)
    {
      case "GET":     onGet
      case "HEAD":    onHead
      case "POST":    onPost
      case "PUT":     onPut
      case "DELETE":  onDelete
      case "OPTIONS": onOptions
      case "TRACE":   onTrace
      default: throw UnsupportedErr("Unsupported method \"$req.method\".")
    }
  }

  **
  ** Convenience method to respond to a GET request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onGet()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a HEAD request.
  ** Default implementation returns a 501 Not implemented error.
  **
  // TODO - make work like servlets
  virtual Void onHead()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a POST request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onPost()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a PUT request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onPut()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a DELETE request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onDelete()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a OPTIONS request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onOptions()
  {
    res.sendError(501)
  }

  **
  ** Convenience method to respond to a TRACE request.
  ** Default implementation returns a 501 Not implemented error.
  **
  virtual Void onTrace()
  {
    res.sendError(501)
  }

}