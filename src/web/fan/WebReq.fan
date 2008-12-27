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
  virtual once Uri absUri()
  {
    host := headers["Host"]
    if (host == null) throw Err("Missing Host header")
    return ("http://" + host + "/").toUri + uri
  }

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
  virtual once Str:Str cookies()
  {
    cookies := Str:Str[:]
    try
    {
      header := headers["Cookie"]
      if (header != null)
      {
        header.split(';', false).each |Str s|
        {
          if (s.isEmpty || s[0] == '$') return
          c := Cookie.fromStr(s)
          cookies[c.name] = c.value
        }
      }
    }
    catch (Err e) e.trace
    return cookies.ro
  }

  **
  ** Get the session associated with this browser "connection".
  ** The session must be accessed the first time before the
  ** response is committed.
  **
  virtual once WebSession session()
  {
    return service.sessionMgr.load(this)
  }

  **
  ** The UserAgent for this request or null if the
  ** "User-Agent" header was not specified in the request.
  **
  virtual once UserAgent? userAgent()
  {
    try
    {
      h := headers["User-Agent"]
      if (h != null) return UserAgent.fromStr(h)
    }
    catch (Err e) e.trace
    return null
  }

  **
  ** Get the key/value pairs of the form data.  If the request
  ** content type is "application/x-www-form-urlencoded", then the
  ** first time this method is called the request content is read
  ** and parsed using `sys::Uri.decodeQuery`.  If the content
  ** type is not "application/x-www-form-urlencoded" this method
  ** returns null.
  **
  virtual once [Str:Str]? form()
  {
    ct := headers.get("Content-Type", "").lower
    if (ct.startsWith("application/x-www-form-urlencoded"))
    {
      len := headers["Content-Length"]
      if (len == null) throw IOErr("Missing Content-Length header")
      return Uri.decodeQuery(in.readLine(len.toInt))
    }
    return null
  }

  **
  ** The InStream for this request.
  **
  abstract InStream in()

  **
  ** Stash allows you to stash objects on the WebReq object
  ** in order to pass data b/w Weblets while processing
  ** this request.
  **
  Str:Obj? stash := Str:Obj?[:]

  **
  ** The namespace object resolved by `uri`.
  **
  Obj? resource


}