//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//

using web

**
** WebRepo is a client implementation of a repository over HTTP
** using a simple REST based API.  `WebRepoMod` implements the
** server side of the fanr HTTP protocol.
**
internal const class WebRepo : Repo
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Make for given URI which must reference a http URI
  new make(Uri uri, Str? username, Str? password)
  {
    this.uri = uri.plusSlash
    this.username = username
    this.password = password
  }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  override const Uri uri

  override PodSpec[] query(Str query, Int numVersions := 1)
  {
    throw Err()
  }

  override PodSpec publish(File podFile)
  {
    throw Err()
  }

  WebClient prepare(Uri path)
  {
    c := WebClient(uri+path)
    c.reqHeaders["Fanr-Uri"] = c.reqUri.relToAuth.encode
    if (username != null) c.reqHeaders["Fanr-Username"] = username
    return c
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str? username
  private const Str? password
}