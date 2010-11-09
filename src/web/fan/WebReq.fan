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
** See [pod doc]`pod-doc#webReq`.
**
abstract class WebReq
{

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
  abstract IpAddr remoteAddr()

  **
  ** Get the IP port of the client socket making this request.
  **
  abstract Int remotePort()

  **
  ** The request URI including the query string relative to
  ** this authority.  Also see `absUri`, `modBase`, and `modRel`.
  **
  ** Examples:
  **   /a/b/c
  **   /a?q=bar
  **
  abstract Uri uri()

  **
  ** The absolute request URI including the full authority
  ** and the query string.  Also see `uri`, `modBase`, and `modRel`.
  ** This method is equivalent to:
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
    return `http://${host}/` + uri
  }

  **
  ** Get the WebMod which is currently responsible
  ** for processing this request.
  **
  abstract WebMod mod

  **
  ** Base URI of the current WebMod.  This Uri always ends in a slash.
  ** This is the URI used to route to the WebMod itself.  The remainder
  ** of `uri` is stored in `modRel` so that the following always
  ** holds true (with exception of a trailing slash):
  **   modBase + modRel == uri
  **
  ** For example if the current WebMod is mounted as '/mod' then:
  **   uri          modBase   modRel
  **   ----------   -------   -------
  **   `/mod`       `/mod/`   ``
  **   `/mod/`      `/mod/`   ``
  **   `/mod?q`     `/mod/`   `?q`
  **   `/mod/a`     `/mod/`   `a`
  **   `/mod/a/b`   `/mod/`   `a/b`
  **
  Uri modBase := `/`
  {
    set
    {
      if (!it.isDir) throw ArgErr("modBase must end in slash");
      if (it.path.size > uri.path.size) throw ArgErr("modBase ($it) is not slice of uri ($uri)");
      &modBase = it
      modRelVal = uri[it.path.size..-1]
    }
  }

  **
  ** WebMod relative part of the URI - see `modBase`.
  **
  Uri modRel() { modRelVal ?: uri }
  private Uri? modRelVal

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
  ** cookies map is readonly and case insensitive.
  **
  virtual once Str:Str cookies()
  {
    try
      return MimeType.parseParams(headers.get("Cookie", "")).ro
    catch (Err e)
      e.trace
    return Str:Str[:].ro
  }

  **
  ** Get the session associated with this browser "connection".
  ** The session must be accessed the first time before the
  ** response is committed.
  **
  abstract WebSession session()

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
  ** Access to socket options for this request.
  **
  abstract SocketOptions socketOptions()

  **
  ** Stash allows you to stash objects on the WebReq object
  ** in order to pass data b/w Weblets while processing
  ** this request.
  **
  Str:Obj? stash := Str:Obj?["web.startTime":Duration.now]

}