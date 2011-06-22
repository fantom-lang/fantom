//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//

using web
using util

**
** WebRepoMod implements basic server side functionality for
** publishing a repo over HTTP to be used by 'WebRepo'. URI
** namespace:
**
**    Method   Uri                    Operation
**    ------   --------------------   ---------
**    GET      {base}/ping            ping meta-data
**    GET      {base}/query?{query}   pod query
**    POST     {base}/query           pod query
**
** HTTP Headers
**    "Fan-NumVersions"   query version limit
**
** Response codes:
**   - 2xx:  okay
**   - 4xx:  client side error (bad request)
**   - 5xx:  server side error
**
** Responses are returned in JSON:
**   - query: '{"pods":[{...},{...}]}'
**   - error: '{"err":"something bad happened"}'
**
const class WebRepoMod : WebMod
{
  ** Constructor, must set `repo`.
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Repository to publish on the web, typically a local FileRepo.
  const Repo repo

  ** Meta-data to include in ping requests.  If customized,
  ** then be sure to include standard props defined by `Repo.ping`.
  const Str:Str pingMeta :=
  [
    "fanr.type":   WebRepo#.toStr,
    "fanr.version": WebRepoMod#.pod.version.toStr
  ]

  ** Service
  override Void onService()
  {
    try
    {
      // ensure URI is formatted as {base}/{cmd}
      uri := req.modRel
      if (uri.path.size != 1) { sendNotFoundErr; return }
      cmd := uri.path.first

      // route to correct command
      if (cmd == "ping")  { onPing; return }
      if (cmd == "query") { onQuery; return }
      sendNotFoundErr
    }
    catch (Err e)
    {
      sendErr(500, e.toStr)
    }
  }

  private Void onPing()
  {
    res.headers["Content-Type"] = "text/plain"
    JsonOutStream(res.out).writeJson(pingMeta).flush
  }

  private Void onQuery()
  {
    // query can be GET query part or POST body
    Str? query
    switch (req.method)
    {
      case "GET":  query = req.uri.queryStr ?: throw Err("Missing '?query' in URI")
      case "POST": query = req.in.readAllStr
      default:     sendErr(501, "Method not implemented"); return
    }

    // get options
    numVersions := Int.fromStr(req.headers["Fan-NumVersions"] ?: "3", 10, false) ?: 3

    // do the query
    PodSpec[]? pods := null
    try
    {
      pods = repo.query(query, numVersions)
    }
    catch (ParseErr e)
    {
      sendErr(400, e.toStr)
      return
    }

    // print results in json format
    res.headers["Content-Type"] = "text/plain"
    out := res.out
    out.printLine("""{"pods":[""")
    pods.each |pod, i|
    {
      out.printLine("{")
      keys := pod.meta.keys
      keys.moveTo("pod.name", 0)
      keys.moveTo("pod.version", 1)
      keys.each |k, j|
      {
        v := pod.meta[k]
        out.print(k.toCode).print(":").print(v.toCode).printLine(j+1<keys.size?",":"")
      }
      out.printLine(i+1 < pods.size ? "}," : "}")
    }
    out.printLine("]}")
  }

//////////////////////////////////////////////////////////////////////////
// Error handling
//////////////////////////////////////////////////////////////////////////

  private Void sendNotFoundErr()
  {
    sendErr(404, "Resource not found: $req.modRel")
  }

  private Void sendErr(Int code, Str msg)
  {
    res.statusCode = code
    res.headers["Content-Type"] = "text/plain"
    res.out.printLine("""{"err":$msg.toCode}""")
  }

}