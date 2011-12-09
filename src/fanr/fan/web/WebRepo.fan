//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//

using web
using util
using concurrent

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
    this.password = password ?: ""
  }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  override const Uri uri

  override Str:Str ping()
  {
    // prepare query
    c := prepare("GET", `ping`)
    c.writeReq.readRes

    // parse json response
    return parseRes(c)
  }

  override PodSpec? find(Str podName, Version? ver, Bool checked := true)
  {
    // prepare query
    c := prepare("GET", ver == null ? `find/${podName}` : `find/${podName}/${ver}`)
    c.writeReq.readRes
    if (c.resCode == 404)
    {
      if (checked) throw UnknownPodErr("$podName-$ver")
      return null
    }

    // parse json response
    jsonRes := parseRes(c)
    return PodSpec(jsonRes, null)
  }

  override PodSpec[] query(Str query, Int numVersions := 1)
  {
    // prepare query
    c := prepare("POST", `query`)
    c.reqHeaders["Fan-NumVersions"] = numVersions.toStr
    c.postStr(query)

    // parse json response
    jsonRes := parseRes(c)
    [Str:Str][] jsonPods := jsonRes["pods"] ?: throw Err("Missing 'pods' in JSON response")
    pods := PodSpec[,]
    pods.capacity = jsonPods.size
    jsonPods.each |json| { pods.add(PodSpec(json, null)) }
    return pods
  }

  override InStream read(PodSpec spec)
  {
    // prepare query
    c := prepare("GET", `pod/$spec.name/$spec.version`)
    c.writeReq.readRes

    // if not 200, then assume a JSON error message
    if (c.resCode != 200) parseRes(c)
    return c.resIn
  }

  override PodSpec publish(File podFile)
  {
    // post file
    c := prepare("POST", `publish`)
    c.reqHeaders["Content-Type"] = "application/zip"
    c.reqHeaders["Content-Length"] = podFile.size.toStr
    c.reqHeaders["Expect"] = "100-continue"
    c.writeReq
    c.readRes
    if (c.resCode != 100) parseRes(c)  // assume JSON error
    podFile.in.pipe(c.reqOut, podFile.size)
    c.reqOut.close
    c.readRes

    // parse json response
    jsonRes := parseRes(c)
    Str:Str jsonSpec := jsonRes["published"] ?: throw Err("Missing 'published' in JSON response")
    return PodSpec(jsonSpec, null)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private WebClient prepare(Str method, Uri path)
  {
    c := WebClient(uri+path)
    c.reqMethod = method
    if (username != null) sign(c)
    return c
  }

  private Void sign(WebClient c)
  {
    // first time we need to query server for algorithms and
    // user salt so we can sign our requests
    if (this.secret.val == null) initForSigning
    secret := Buf.fromBase64(this.secret.val)

    // add signing headers which are included in signature
    c.reqHeaders["Fanr-Username"]           = username
    c.reqHeaders["Fanr-SecretAlgorithm"]    = secretAlgorithm.val
    c.reqHeaders["Fanr-SignatureAlgorithm"] = "HMAC-SHA1"
    c.reqHeaders["Fanr-Ts"]                 = (DateTime.nowUtc + tsSkew.val).toStr

    // compute signature and add header
    s := toSignatureBody(c.reqMethod, c.reqUri, c.reqHeaders)
    c.reqHeaders["Fanr-Signature"] = s.hmac("SHA1",secret).toBase64
  }

  internal static Buf toSignatureBody(Str method, Uri uri, Str:Str headers)
  {
    s := Buf()
    s.printLine(method.upper)
    s.printLine(uri.encode.lower)
    keys := headers.keys.findAll |key|
    {
      key = key.lower
      return key.startsWith("fanr-") && key != "fanr-signature"
    }
    keys.sort.each |key|
    {
      s.print(key.lower).print(":").printLine(headers[key])
    }
    return s
  }

  private Void initForSigning()
  {
    // if we don't have HMAC, then first thing we need to do is
    // ping server to get the salt for our username
    c := WebClient(uri+`auth?$username`)
    c.writeReq.readRes
    res := parseRes(c)

    // get timestamp and store away delta so our requests
    // are in-sync even if our clocks are not
    ts := DateTime.fromStr(res["ts"] ?: throw Err("Response missing 'ts'"))
    tsSkew.val = ts - DateTime.now

    // check signature algorithms, we only support HMAC-SHA1 so
    // if server doesn't support that we have to give up now
    sigAlgorithms := res["signatureAlgorithms"] as Str ?: throw Err("Response missing 'signatureAlgorithms'")
    if (sigAlgorithms.split(',').find |a| { a.upper == "HMAC-SHA1" } == null)
      throw Err("Unsupported signature algorithms: $sigAlgorithms")

    // compute secret using secret algorithm
    secretAlgorithms := res["secretAlgorithms"] as Str ?: throw Err("Response missing 'secretAlgorithms'")
    secret.val = secretAlgorithms.split(',').eachWhile |a|
    {
      // save current normalized algorithm name
      secretAlgorithm.val = a = a.upper

      if (a == "PASSWORD")
      {
        return Buf().print(password).toBase64
      }

      if (a.upper == "SALTED-HMAC-SHA1")
      {
        salt := res["salt"] ?: throw Err("Response missing 'salt'")
        return Buf().print("$username:$salt").hmac("SHA-1", password.toBuf).toBase64
      }

      return null
    }
    if (secret.val == null) throw Err("Unsupported secret algorithms: $secretAlgorithms")
  }

  private Str:Obj? parseRes(WebClient c)
  {
    // first parse the JSON
    Obj? json
    try
      json = JsonInStream(c.resIn).readJson
    catch (Err e)
      throw RemoteErr("Cannot parse response as JSON [$c.resCode]", e)

    // make sure response is a Map
    map := json as Str:Obj?
    if (map == null)
      throw RemoteErr("Invalid JSON response: ${json?.typeof}")

    // check response code
    if (c.resCode / 100 == 2) return map

    // should have an err message
    err := map["err"] ?: "Unknown error"
    throw RemoteErr("$err [$c.resCode]")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str? username                        // user name
  private const Str password                         // plain text password
  private const AtomicRef secret := AtomicRef(null)  // base64 string
  private const AtomicRef secretAlgorithm := AtomicRef(null)  // algorithm we picked for secret
  private const AtomicRef tsSkew := AtomicRef(0sec)  // diff b/w my clock and server clock
}

internal const class RemoteErr : Err
{
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}