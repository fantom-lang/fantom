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
mixin Weblet
{

//////////////////////////////////////////////////////////////////////////
// Request/Response
//////////////////////////////////////////////////////////////////////////

  **
  ** The WebReq instance for this current web request.  Raise an exception
  ** if the current actor thread is not serving a web request.
  **
  WebReq req()
  {
    try
      return Actor.locals["web.req"]
    catch (NullErr e)
      throw Err("No web request active in thread")
  }

  **
  ** The WebRes instance for this current web request.  Raise an exception
  ** if the current actor thread is not serving a web request.
  **
  WebRes res()
  {
    try
      return Actor.locals["web.res"]
    catch (NullErr e)
      throw Err("No web request active in thread")
  }

//////////////////////////////////////////////////////////////////////////
// Service Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Service a web request. The default implementation routes
  ** to `onGet`, `onPost`, etc based on the request's method.
  **
  virtual Void onService()
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
      default:        res.sendError(501)
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