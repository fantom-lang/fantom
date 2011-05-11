//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//

using web

**
** WebRepoMod implements basic server side functionality for
** publishing a repo over HTTP to be used by `WebRepo`. URI
** namespace:
**
**    Method   Uri                    Operation
**    ------   --------------------   ---------
**    GET      {base}/query?{query}   pod query
**    POST     {base}/query           pod query
**
** HTTP Headers
**    "Fan-NumVersions"   query version limit
**
const class WebRepoMod : WebMod
{
  ** Constructor, must set `repo`.
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Repository to publish on the web, typically a local FileRepo.
  const Repo repo

  ** Service
  override Void onService()
  {
    // ensure URI is formatted as {base}/{cmd}
    uri := req.modRel
    if (uri.path.size != 1) { res.sendErr(404); return }
    cmd := uri.path.first

    // route to correct command
    if (cmd == "query") { onQuery; return }
    res.sendErr(404)
  }

  private Void onQuery()
  {
    // query can be GET query part or POST body
    Str? query
    switch (req.method)
    {
      case "GET":  query = req.uri.queryStr
      case "POST": query = req.in.readAllStr
      default:     res.sendErr(501); return
    }

    // get options
    numVersions := Int.fromStr(req.headers["Fan-NumVersions"] ?: "1", 10, false) ?: 1

throw Err("TODO")
  }
}