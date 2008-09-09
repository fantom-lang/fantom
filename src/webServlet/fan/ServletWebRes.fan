//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 06  Andy Frank  Creation
//

using web

**
** ServletEngine implementation of WebRes.
**
internal class ServletWebRes : WebRes
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(ServletEnv env, WebOutStream out)
  {
    _env = env
    _out = out
  }

//////////////////////////////////////////////////////////////////////////
// WebRes
//////////////////////////////////////////////////////////////////////////

// TODO  override WebEnv env() { return _env }

  override Int statusCode
  {
    set { setStatus(@statusCode = val) }
  }
  native Void setStatus(Int sc)

  override Str:Str headers() { return _headers }

  override native Bool isCommitted()

  native Void commit()

  override WebOutStream out()
  {
    if (!isCommitted())
    {
      _headers = _headers.ro
      commit()
    }
    return _out
  }

  native Void setHeader(Str name, Str value)

  override Void redirect(Int statusCode, Uri uri)
  {
    // We don't use the servlet API here, because it does
    // not allow you to specify the statusCode

    // User WebRes API to check for commit, and then commit
    this.statusCode = statusCode
    headers["Location"] = uri.toStr
    headers["Content-Length"] = "0"
    out
  }

  override native Void sendError(Int statusCode, Str msg := null)

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal ServletEnv _env
  internal WebOutStream _out
  internal Str:Str _headers := Str:Str[:]

}