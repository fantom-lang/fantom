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

  override Str:Str ping()
  {
    // prepare query
    c := prepare(`ping`)
    c.writeReq.readRes

    // parse json response
    return parseRes(c)
  }

  override PodSpec[] query(Str query, Int numVersions := 1)
  {
    // prepare query
    c := prepare(`query`)
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

  override PodSpec publish(File podFile)
  {
    // post file
    c := prepare(`publish`)
    c.postFile(podFile)

    // parse json response
    jsonRes := parseRes(c)
    Str:Str jsonSpec := jsonRes["published"] ?: throw Err("Missing 'published' in JSON response")
    return PodSpec(jsonSpec, null)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private WebClient prepare(Uri path)
  {
    c := WebClient(uri+path)
    c.reqHeaders["Fanr-Uri"] = c.reqUri.relToAuth.encode
    if (username != null) c.reqHeaders["Fanr-Username"] = username
    return c
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

  private const Str? username
  private const Str? password
}

internal const class RemoteErr : Err
{
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}