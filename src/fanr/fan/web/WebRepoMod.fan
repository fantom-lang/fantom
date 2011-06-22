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
**    Method   Uri                      Operation
**    ------   --------------------     ---------
**    GET      {base}/ping              ping meta-data
**    GET      {base}/query?{query}     pod query
**    POST     {base}/query             pod query
**    GET      {base}/pod/{name}/{ver}  pod download
**    POST     {base}/publish           publish pod
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

  ** Dir to store temp files, defaults to 'Env.tempDir'
  const File tempDir := Env.cur.tempDir

//////////////////////////////////////////////////////////////////////////
// Service Routing
//////////////////////////////////////////////////////////////////////////

  ** Service
  override Void onService()
  {
    try
    {
      // route to correct command
      path := req.modRel.path
      cmd := path.getSafe(0) ?: "?"
      if (cmd == "ping"    && path.size == 1) { onPing; return }
      if (cmd == "query"   && path.size == 1) { onQuery; return }
      if (cmd == "pod"     && path.size == 3) { onPod(path[1], path[2]); return }
      if (cmd == "publish" && path.size == 1) { onPublish; return }
      sendNotFoundErr
    }
    catch (Err e)
    {
      sendErr(500, e.toStr)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Ping
//////////////////////////////////////////////////////////////////////////

  private Void onPing()
  {
    res.headers["Content-Type"] = "text/plain"
    JsonOutStream(res.out).writeJson(pingMeta).flush
  }

//////////////////////////////////////////////////////////////////////////
// Query
//////////////////////////////////////////////////////////////////////////

  private Void onQuery()
  {
    // query can be GET query part or POST body
    Str? query
    switch (req.method)
    {
      case "GET":  query = req.uri.queryStr ?: throw Err("Missing '?query' in URI")
      case "POST": query = req.in.readAllStr
      default:     sendBadMethodErr
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
    pods.each |pod, i| { printPodSpecJson(out, pod, i+1 < pods.size) }
    out.printLine("]}")
  }

//////////////////////////////////////////////////////////////////////////
// Read Pod
//////////////////////////////////////////////////////////////////////////

  private Void onPod(Str podName, Str podVer)
  {
    // lookup pod that matches name/version
    query := "$podName $podVer"
    spec := repo.query(query, 100).find |p| { p.version.toStr == podVer }
    if (spec == null)  { sendErr(404, "No pod match: $query"); return }

    // pipe repo stream to response stream
    res.headers["Content-Type"] = "application/zip"
    if (spec.size != null) res.headers["Content-Length"] = spec.size.toStr
    repo.read(spec).pipe(res.out, spec.size)
  }

//////////////////////////////////////////////////////////////////////////
// Publish
//////////////////////////////////////////////////////////////////////////

  private Void onPublish()
  {
    if (req.method != "POST") { sendBadMethodErr; return }

    // allocate temp file
    tempName := "fanr-" + DateTime.now.toLocale("YYMMDDhhmmss") + "-" + Buf.random(4).toHex + ".pod"
    tempFile := tempDir + tempName.toUri

    try
    {
      // read input to temp file
      tempOut := tempFile.out
      len := req.headers["Content-Length"]?.toInt ?: null
      try
        req.in.pipe(tempOut, len)
      finally
        tempOut.close

      // publish to local repo
      spec := repo.publish(tempFile)

      // return JSON response
      res.headers["Content-Type"] = "text/plain"
      out := res.out
      out.printLine("""{"published":""")
      printPodSpecJson(out, spec, false)
      out.printLine("""}""")
    }
    finally
    {
      try { tempFile.delete } catch {}
    }
  }

//////////////////////////////////////////////////////////////////////////
// Response/Error Handling
//////////////////////////////////////////////////////////////////////////

  private Void printPodSpecJson(OutStream out, PodSpec pod, Bool comma)
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
    out.printLine(comma ? "}," : "}")
  }

  private Void sendNotFoundErr()
  {
    sendErr(404, "Resource not found: $req.modRel")
  }

  private Void sendBadMethodErr()
  {
    sendErr(501, "Method not implemented: $req.method")
  }

  private Void sendErr(Int code, Str msg)
  {
    res.statusCode = code
    res.headers["Content-Type"] = "text/plain"
    res.out.printLine("""{"err":$msg.toCode}""")
  }

}