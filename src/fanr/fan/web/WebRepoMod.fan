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
**    Method   Uri                       Operation
**    ------   --------------------      ---------
**    GET      {base}/ping               ping meta-data
**    GET      {base}/find/{name}        pod find current
**    GET      {base}/find/{name}/{ver}  pod find
**    GET      {base}/query?{query}      pod query
**    POST     {base}/query              pod query
**    GET      {base}/pod/{name}/{ver}   pod download
**    POST     {base}/publish            publish pod
**    GET      {base}/auth?{username}    authentication info
**
** See [Web Repos]`docFanr::WebRepos`.
**
**
const class WebRepoMod : WebMod
{
  ** Constructor, must set `repo`.
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Repository to publish on the web, typically a local FileRepo.
  const Repo repo

  ** Authentication and authorization plug-in.
  ** Default is to make everything completely public.
  const WebRepoAuth auth := PublicWebRepoAuth()

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
      // if user was specified, then authenticate to user object
      user := authenticate
      if (res.isDone) return

      // route to correct command
      path := req.modRel.path
      cmd := path.getSafe(0) ?: "?"
      if (cmd == "find"    && path.size == 2) { onFind(path[1], null, user); return }
      if (cmd == "find"    && path.size == 3) { onFind(path[1], path[2], user); return }
      if (cmd == "query"   && path.size == 1) { onQuery(user); return }
      if (cmd == "pod"     && path.size == 3) { onPod(path[1], path[2], user); return }
      if (cmd == "publish" && path.size == 1) { onPublish(user); return }
      if (cmd == "ping"    && path.size == 1) { onPing(user); return }
      if (cmd == "auth"    && path.size == 1) { onAuth(user); return }
      sendNotFoundErr
    }
    catch (Err e)
    {
      if (!res.isCommitted) sendErr(500, e.toStr)
      else throw e
    }
  }

  private Obj? authenticate()
  {
    // if username header wasn't specified, then assume public request
    username := req.headers["Fanr-Username"]
    if (username == null) return null

    // check that user name is valid
    user := auth.user(username)
    if (user == null)
    {
      sendUnauthErr("Invalid username: $username")
      return null
    }

    // get signature headers
    signAlgorithm   := getRequiredHeader("Fanr-SignatureAlgorithm")
    secretAlgorithm := getRequiredHeader("Fanr-SecretAlgorithm").upper
    signature       := getRequiredHeader("Fanr-Signature")
    ts              := DateTime.fromStr(getRequiredHeader("Fanr-Ts"))

    // check timestamp is in ball-park of now to prevent replay
    // attacks, but give some fudge since clocks are never in sync
    if ((now - ts).abs > 15min)
    {
      sendUnauthErr("Invalid timestamp window for signature: $ts != $now")
      return null
    }

    // verify signature algorithm (we currently only support one algorithm)
    if (signAlgorithm != "HMAC-SHA1")
    {
      sendUnauthErr("Unsupported signature algorithm: $signAlgorithm")
      return null
    }

    // verify signature which in effect is the password verification
    s := WebRepo.toSignatureBody(req.method, req.absUri, req.headers)
    secret := auth.secret(user, secretAlgorithm)
    expectedSignature := s.hmac("SHA-1", secret).toBase64
    if (expectedSignature != signature)
    {
      sendUnauthErr("Invalid password (invalid signature)")
      return null
    }

    // at this point we have authenticated the user
    return user
  }

//////////////////////////////////////////////////////////////////////////
// Ping
//////////////////////////////////////////////////////////////////////////

  private Void onPing(Obj? user)
  {
    // add "ts" to configured meta
    props := pingMeta.dup
    props["ts"] =  DateTime.now.toStr

    res.headers["Content-Type"] = "text/plain"
    JsonOutStream(res.out).writeJson(props).flush
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  private Void onFind(Str podName, Str? verStr, Obj? user)
  {
    // if user can't read any pods, immediately bail
    if (!auth.allowQuery(user, null)) { sendForbiddenErr(user); return }

    // lookup pod that matches name/version
    Version? ver := null
    if (verStr != null)
    {
      ver = Version.fromStr(verStr, false)
      if (ver == null)  { sendErr(404, "Invalid version: $verStr"); return }
    }
    spec := repo.find(podName, ver, false)
    if (spec == null)  { sendErr(404, "Pod not found: $podName-$ver"); return }

    // verify permissions
    if (!auth.allowQuery(user, spec)) { sendForbiddenErr(user); return }

    // return result
    res.headers["Content-Type"] = "text/plain"
    printPodSpecJson(res.out, spec, false)
  }

//////////////////////////////////////////////////////////////////////////
// Query
//////////////////////////////////////////////////////////////////////////

  private Void onQuery(Obj? user)
  {
    // if user can't query any pods, immediately bail
    if (!auth.allowQuery(user, null)) { sendForbiddenErr(user); return }

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

    // filter out any pods the user is not allowed to query
    pods = pods.findAll |pod| { auth.allowQuery(user, pod) }

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

  private Void onPod(Str podName, Str podVer, Obj? user)
  {
    // if user can't read any pods, immediately bail
    if (!auth.allowRead(user, null)) { sendForbiddenErr(user); return }

    // lookup pod that matches name/version
    query := "$podName $podVer"
    spec := repo.query(query, 100).find |p| { p.version.toStr == podVer }
    if (spec == null)  { sendErr(404, "No pod match: $query"); return }

    // check permissions
    if (!auth.allowRead(user, spec)) { sendForbiddenErr(user); return }

    // pipe repo stream to response stream
    res.headers["Content-Type"] = "application/zip"
    if (spec.size != null) res.headers["Content-Length"] = spec.size.toStr
    repo.read(spec).pipe(res.out, spec.size)
  }

//////////////////////////////////////////////////////////////////////////
// Publish
//////////////////////////////////////////////////////////////////////////

  private Void onPublish(Obj? user)
  {
    if (req.method != "POST") { sendBadMethodErr; return }

    // if user can't publish any pods, immediately bail
    if (!auth.allowPublish(user, null)) { sendForbiddenErr(user); return }

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

      // check if user can publish this specific pod
      spec := PodSpec.load(tempFile)
      if (!auth.allowPublish(user, spec)) { sendForbiddenErr(user); return }

      // publish to local repo
      spec = repo.publish(tempFile)

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
// Auth
//////////////////////////////////////////////////////////////////////////

  private Void onAuth(Obj? reqUser)
  {
    if (req.method != "GET") { sendBadMethodErr; return }

    username     := req.uri.queryStr ?: "*"
    user         := auth.user(username)
    salt         := auth.salt(user)
    secrets      := auth.secretAlgorithms.join(",")
    signatures   := auth.signatureAlgorithms.join(",")

    res.headers["Content-Type"] = "text/plain"
    out := res.out
    out.printLine("""{""")
    out.printLine(""" "username":$username.toCode,""")
    if (salt != null) out.printLine(""" "salt":$salt.toCode,""")
    out.printLine(""" "secretAlgorithms":$secrets.toCode,""")
    out.printLine(""" "signatureAlgorithms":$signatures.toCode,""")
    out.printLine(""" "ts":$now.toStr.toCode""")
    out.printLine("""}""")
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

  private Str getRequiredHeader(Str key)
  {
    req.headers[key] ?: throw Err("Missing required header $key.toCode")
  }

  private Void sendUnauthErr(Str msg)
  {
    sendErr(401, msg)
  }

  private Void sendForbiddenErr(Obj? user)
  {
    if (user == null) sendErr(401, "Authentication required")
    else sendErr(403, "Not allowed")
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
    res.out.printLine("""{"err":$msg.toCode}""").close
    res.done
  }

  private DateTime now() { DateTime.nowUtc(null) }

}