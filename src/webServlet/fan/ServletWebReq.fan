//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 06  Andy Frank  Creation
//

using web

**
** ServletEngine implementation of WebReq.
**
internal class ServletWebReq : WebReq
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(ServletEnv env, InStream in)
  {
    _env = env
    _in  = in
  }

//////////////////////////////////////////////////////////////////////////
// WebReq
//////////////////////////////////////////////////////////////////////////

// TODO  override WebEnv env()       { return _env }
  override Str method()       { return _method }
  override Version version()  { return _version}
  override Uri uri()          { return _uri }
  override Uri prefixUri()    { return _prefixUri }
  override Uri suffixUri()    { return _suffixUri }
  override Str:Str headers()  { return _headers }
  override UserAgent userAgent() { return _userAgent }
  override Str:Obj stash()    { return _stash }
  override InStream in()      { return _in }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal ServletEnv _env
  internal Str _method
  internal Version _version
  internal Uri _uri
  internal Uri _prefixUri
  internal Uri _suffixUri
  internal Str:Str _headers := Str:Str[:]
  internal UserAgent _userAgent
  internal Str:Obj _stash := Str:Obj[:]
  internal InStream _in

}