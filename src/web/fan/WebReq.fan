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
  ** Return if the method is GET
  **
  abstract Bool isGet()

  **
  ** Return if the method is POST
  **
  abstract Bool isPost()

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
  ** and case insensitive (see `sys::Map.caseInsensitive`).
  **
  ** Examples:
  **   req.headers["Accept-Language"]
  **
  abstract Str:Str headers()

  **
  ** Get the accepted locales for this request based on the
  ** "Accept-Language" HTTP header.  List is sorted by preference, where
  ** 'locales.first' is best, and 'locales.last' is worst.  This list is
  ** guarenteed to contain Locale("en").
  **
  virtual once Locale[] locales()
  {
    list := Locale[,]
    hval := headers["Accept-Language"]
    if (hval != null)
    {
      WebUtil.parseList(hval).each |val|
      {
        try
        {
          colon := val.index(";q=")
          qual  := colon==null ? 1f : val[colon+3..-1].toFloat
          lang  := colon==null ? val : val[0..<colon]
          loc   := Locale.fromStr(lang, false)
          if (qual > 0f && loc != null && !list.contains(loc)) list.add(loc)
        }
        catch (Err err) { err.trace }
      }
    }

    // make sure we always have 'en'
    en := Locale("en")
    if (!list.contains(en)) list.add(en)
    return list
  }

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
  ** Get the stream to read request body.  See `WebUtil.makeContentInStream`
  ** to check under which conditions request content is available.
  ** If request content is not available, then throw an exception.
  **
  ** If the client specified the "Expect: 100-continue" header, then the first
  ** access of the request input stream will automatically send the client
  ** a [100 Continue]`pod-doc#expectContinue` response.
  **
  abstract InStream in()

  **
  ** Access to socket options for this request.
  **
  abstract SocketOptions socketOptions()

  **
  ** Access to underlying socket - internal use only!
  **
  @NoDoc abstract TcpSocket socket()

  **
  ** Stash allows you to stash objects on the WebReq object
  ** in order to pass data b/w Weblets while processing
  ** this request.
  **
  virtual Str:Obj? stash() { stashRef }
  private Str:Obj? stashRef := Str:Obj?["web.startTime":Duration.now]

  **
  ** Given a web request:
  **   1. check that the content-type is form-data
  **   2. get the boundary string
  **   3. invoke callback for each part (see `WebUtil.parseMultiPart`)
  **
  ** For each part in the stream call the given callback function with
  ** the part's form name, headers, and an input stream used to read the
  ** part's body.
  **
  Void parseMultiPartForm(|Str formName, InStream in, Str:Str headers| cb)
  {
    mime := MimeType(this.headers["Content-Type"])
    if (mime.subType != "form-data") throw Err("Invalid content-type: $mime")
    boundary := mime.params["boundary"] ?: throw Err("Missing boundary param: $mime")
    WebUtil.parseMultiPart(this.in, boundary) |partHeaders, partIn|
    {
      cd := partHeaders["Content-Disposition"] ?: throw Err("Multi-part missing Content-Disposition")
      semi := cd.index(";") ?: throw Err("Expected semicolon; Content-Disposition: $cd")
      params := MimeType.parseParams(cd[cd.index(";")+1..-1])
      formName := params["name"] ?: throw Err("Expected name param; Content-Disposition: $cd")
      cb(formName, partIn, partHeaders)
      try { partIn.skip(Int.maxVal) } catch {} // drain stream
    }
  }

}