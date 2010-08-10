//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 07  Brian Frank  Creation
//

**
** FileWeblet is used to service an HTTP request on a `sys::File`.
** It handles all the dirty details for cache control, modification
** time, ETags, etc.
**
** Current implementation supports ETags and Modification time
** for cache validation.  It does not specify any cache control
** directives.
**
class FileWeblet : Weblet
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor with file to service.
  **
  **
  new make(File file)
  {
    if (file.isDir) throw ArgErr("FileWeblet cannot process dir")
    this.file = file
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** The file being serviced by this FileWeblet.
  **
  const File file

  **
  ** Get the modified time of the file floored to 1 second
  ** which is the most precise that HTTP can deal with.
  **
  virtual DateTime modified()
  {
    return file.modified.floor(1sec)
  }

  **
  ** Compute the ETag for the file being serviced which uniquely
  ** identifies the file version.  The default implementation is
  ** a hash of the modified time and the file size.  The result
  ** of this method must conform to the ETag syntax and be
  ** wrapped in quotes.
  **
  virtual Str etag()
  {
    return "\"" + file.size.toHex + "-" + file.modified.ticks.toHex + "\""
  }

//////////////////////////////////////////////////////////////////////////
// Weblet
//////////////////////////////////////////////////////////////////////////

  **
  ** Handle GET request for the file.
  **
  override Void onGet()
  {
    // if file doesn't exist
    if (!file.exists) { res.sendErr(404); return }

    // set identity headers
    res.headers["ETag"] = etag
    res.headers["Last-Modified"] = modified.toHttpStr

    // check if we can return a 304 not modified
    if (checkNotModified) return

    // service a normal 200
    res.statusCode = 200
    mime := file.mimeType
    if (mime != null) res.headers["Content-Type"] = mime.toStr
    res.headers["Content-Length"] = file.size.toStr
    file.in.pipe(res.out, file.size)
  }

  **
  ** Check if the request passed headers indicating it has
  ** cached version of the file.  If the file has not been
  ** modified, then service the request as 304 and return
  ** true.  This method supports ETag "If-None-Match" and
  ** "If-Modified-Since" modification time.
  **
  virtual protected Bool checkNotModified()
  {
    // check If-Match-None
    matchNone := req.headers["If-None-Match"]
    if (matchNone != null)
    {
      etag := this.etag
      match := WebUtil.parseList(matchNone).any |Str s->Bool|
      {
        return s == etag || s == "*"
      }
      if (match)
      {
        res.statusCode = 304
        return true
      }
    }

    // check If-Modified-Since
    since := req.headers["If-Modified-Since"]
    if (since != null)
    {
      sinceTime := DateTime.fromHttpStr(since, false)
      if (modified == sinceTime)
      {
        res.statusCode = 304
        return true
      }
    }

    // gotta do it the hard way
    return false
  }

}