//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 06  Andy Frank  Creation
//

using inet

**
** WebReq encapsulates a web request.
**
** See [docLib::Web]`docLib::Web#webReq`
**
abstract class WebReq
{

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the WebService managing the request.
  **
  abstract WebService service()

  **
  ** The HTTP request method in uppercase. Example: GET, POST, PUT.
  **
  abstract Str method()

  **
  ** The HTTP version of the request.
  **
  abstract Version version()

  **
  ** Get the IP host address of the client socket making this request.
  **
  abstract IpAddress remoteAddress()

  **
  ** Get the IP port of the client socket making this request.
  **
  abstract Int remotePort()

  **
  ** The request URI including the query string relative
  ** to this authority.  Also see `absUri`.
  **
  ** Examples:
  **   /a/b/c
  **   /a?q=bar
  **
  abstract Uri uri()

  **
  ** The absolute request URI including the full authority
  ** and the query string.  Also see `uri`.  This method is
  ** equivalent to:
  **   "http://" + headers["Host"] + uri
  **
  ** Examples:
  **   http://www.foo.com/a/b/c
  **   http://www.foo.com/a?q=bar
  **
  abstract Uri absUri()

  **
  ** Map of HTTP request headers.  The headers map is readonly
  ** and case sensitive (see `sys::Map.caseInsensitive`).
  **
  ** Examples:
  **   req.headers["Accept-Language"]
  **
  abstract Str:Str headers()

  **
  ** Map of cookie values keyed by cookie name.  The
  ** cookies map is readonly and case sensitive.
  **
  abstract Str:Str cookies()

  **
  ** Get the session associated with this browser "connection".
  ** The session must be accessed the first time before the
  ** response is committed.
  **
  once WebSession session()
  {
    return service.sessionMgr.load(this)
  }

  **
  ** The UserAgent for this request or null if the
  ** "User-Agent" header was not specified in the request.
  **
  abstract UserAgent? userAgent()

  **
  ** Get the key/value pairs of the form data.  If the request
  ** content type is "application/x-www-form-urlencoded", then the
  ** first time this method is called the request content is read
  ** and parsed using `sys::Uri.decodeQuery`.  If the content
  ** type is not "application/x-www-form-urlencoded" this method
  ** returns null.
  **
  abstract [Str:Str]? form()

  **
  ** The InStream for this request.
  **
  abstract InStream in()

  **
  ** Stash allows you to stash objects on the WebReq object
  ** in order to pass data b/w Weblets while processing
  ** this request.
  **
  abstract Str:Obj stash()

  **
  ** The namespace object resolved by `uri`.
  **
  Obj? resource


}