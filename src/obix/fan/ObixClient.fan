//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 May 09  Brian Frank  Creation
//

using web
using concurrent

**
** ObixClient implements the client side of the oBIX
** HTTP REST protocol.
**
class ObixClient
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with lobby URI and authentication credentials.
  **
  new make(Uri lobby, Str username, Str password)
  {
    this.lobbyUri = lobby.plusSlash
    this.username = username
    this.authHeader = "Basic " + "$username:$password".toBuf.toBase64
  }

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  **
  ** Uri of the lobby object
  **
  const Uri lobbyUri

  **
  ** Username to use for authentication, or null if not
  ** using authentication.
  **
  const Str username

  **
  ** About object relative URI - either set manually or via `readLobby`.
  **
  Uri? aboutUri

  **
  ** Batch operation relative URI - either set manually or via `readLobby`.
  **
  Uri? batchUri

  **
  ** Watch service relative URI - either set manually or via `readLobby`
  **
  Uri? watchServiceUri

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  **
  ** Read the lobby object.  This method will set the
  ** `aboutUri` and `batchUri` fields.
  **
  ObixObj readLobby()
  {
    lobby := read(lobbyUri)
    aboutUri = lobby.get("about", false)?.href
    batchUri = lobby.get("batch", false)?.href
    watchServiceUri = lobby.get("watchService", false)?.href
    return lobby
  }

  **
  ** Read about object.  The `aboutUri` must be either set
  ** manually or via `readLobby`.
  **
  ObixObj readAbout()
  {
    if (aboutUri == null) throw Err("aboutUri not set")
    return read(aboutUri)
  }

  **
  ** Perform a batch read for all the given URIs.  The
  ** `batchUri` must be either set manually or via `readLobby`.
  **
  ObixObj[] batchRead(Uri[] uris)
  {
    // sanity checks
    if (batchUri == null) throw Err("batchUri not set")
    if (uris.isEmpty) return ObixObj[,]

    // if only one
    if (uris.size == 1) return [ read(uris[0]) ]

    // build batch-in argument
    in := ObixObj { elemName = "list"; contract = Contract.batchIn }
    baseUri := lobbyUri.pathOnly
    uris.each |uri|
    {
      in.add(ObixObj{elemName = "uri"; contract = Contract.read; val = baseUri + uri })
    }

    // invoke the request
    out := invoke(batchUri, in)
    if (out.elemName == "err") throw Err(out.toStr)

    // return the list of children
    return out.list
  }

  **
  ** Create a new watch from via `watchServiceUri` and return the
  ** object which represents the watch.  Raise err if watch service
  ** isn't available.
  **
  ObixClientWatch watchOpen()
  {
    // must have watchServiceUri configured
    if (watchServiceUri == null) throw Err("watchService is not avaialble")

    // lazily populate WatchService.make URI
    if (watchServiceMakeUri == null)
    {
      service := read(watchServiceUri)
      makeOp := service.get("make")
      if (makeOp.href == null) throw Err("WatchService.make missing href")
      watchServiceMakeUri = watchServiceUri + makeOp.href
    }

    // invoke the make op
    watch := invoke(watchServiceMakeUri, ObixObj())
    return ObixClientWatch(this, watch)
  }

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Read an obix document with the specified href.
  ** If the result is an '<err>' object, then throw
  ** an ObixErr with the object.
  **
  ObixObj read(Uri uri)
  {
    debugId := debugCounter.getAndIncrement
    c := makeReq(uri, "GET")
    if (log.isDebug) log.debug("> [$debugId] GET $c.reqUri")
    c.writeReq.readRes
    if (log.isDebug) log.debug("< [$debugId] $c.resCode")
    return readResObj(c)
  }

  **
  ** Write an obix document to the specified href and return
  ** the server's result.  If the result is an '<err>' object,
  ** then throw an ObixErr with the object.
  **
  ObixObj write(ObixObj obj) { post(obj.href, "PUT", obj) }

  **
  ** Invoke the operation identified by the specified href.
  ** If the result is* an '<err>' object, then throw an ObixErr
  ** with the object.
  **
  ObixObj invoke(Uri uri, ObixObj in) { post(uri, "POST", in) }

  private WebClient makeReq(Uri uri, Str method)
  {
    uri = lobbyUri + uri
    c := WebClient(uri)
    c.reqMethod = method
    c.reqHeaders["Content-Type"]  = "text/xml; charset=utf-8"
    c.reqHeaders["Authorization"] = authHeader
    return c
  }

  private ObixObj post(Uri uri, Str method, ObixObj in)
  {
    debugId := debugCounter.getAndIncrement
    c := makeReq(uri, method)
    if (log.isDebug) log.debug("> [$debugId] $method $c.reqUri")
    c.writeReq
    in.writeXml(c.reqOut)
    c.reqOut.close
    c.readRes
    if (log.isDebug) log.debug("< [$debugId] $c.resCode")
    if (c.resCode == 100) c.readRes
    return readResObj(c)
  }

  private static ObixObj readResObj(WebClient c)
  {
    if (c.resCode != 200) throw IOErr("Bad HTTP response: $c.resCode $c.reqUri")
    obj := ObixObj.readXml(c.resIn)
    if (obj.elemName == "err") throw ObixErr(obj)
    return obj
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  static Void main(Str[] args)
  {
    c := ObixClient(args[0].toUri, "", "")
    c.readLobby
    about := c.readAbout
    about.writeXml(Env.cur.out)
    echo(about->serverName)
    echo(about->vendorName)
    echo(about->productName)
    echo(about->productVersion)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const AtomicInt debugCounter := AtomicInt()

  @NoDoc Log log := Log.get("obix")

  private Str authHeader
  private Uri? watchServiceMakeUri
}

**************************************************************************
** ObixClientWatch
**************************************************************************

**
** Represents a clients side watch for an `ObixClient`
**
class ObixClientWatch
{
  ** Constructor used by ObixClient.watchOpen
  internal new make(ObixClient client, ObixObj obj)
  {
    if (obj.href == null)
      throw Err("Server returned Watch without href: $obj")

    this.client = client
    this.uri = obj.href
    this.leaseUri       = childUri(obj, "lease",       "reltime")
    this.addUri         = childUri(obj, "add",         "op")
    this.removeUri      = childUri(obj, "remove",      "op")
    this.pollChangesUri = childUri(obj, "pollChanges", "op")
    this.pollRefreshUri = childUri(obj, "pollRefresh", "op")
    this.deleteUri      = childUri(obj, "delete",      "op")
  }

  private Uri childUri(ObixObj obj, Str name, Str elem)
  {
    child := obj.get(name)
    if (child.elemName != elem) throw Err("Expecting Watch.$name to be $elem, not $child.elemName")
    if (child.href == null) throw Err("Missing href for Watch.$name")
    return this.uri + child.href
  }

  ** Associated client
  ObixClient client { private set }

  ** Get or set the watch lease time on the server
  Duration lease
  {
    get { client.read(leaseUri).val as Duration ?: throw Err("Invalid lease val") }
    set { newVal := it; client.write(ObixObj { href = leaseUri; val = newVal }) }
  }

  ** Add URIs to the watch.
  ObixObj[] add(Uri[] uris)
  {
    if (uris.isEmpty) return ObixObj[,]
    return fromWatchOut(client.invoke(addUri, toWatchIn(uris)))
  }

  ** Remove URIs from the watch.
  Void remove(Uri[] uris)
  {
    if (uris.isEmpty) return
    client.invoke(removeUri, toWatchIn(uris))
  }

  ** Poll for changes to get state of only objects which have changed.
  ObixObj[] pollChanges()
  {
    fromWatchOut(client.invoke(pollChangesUri, nullArg))
  }

  ** Poll refresh to get current state of every URI in watch
  ObixObj[] pollRefresh()
  {
    fromWatchOut(client.invoke(pollRefreshUri, nullArg))
  }

  ** Close the watch down on the server side.
  Void close()
  {
    client.invoke(deleteUri, nullArg)
  }

  private ObixObj nullArg() { ObixObj() }

  private ObixObj toWatchIn(Uri[] uris)
  {
    list := ObixObj { elemName = "list"; name = "hrefs";  }
    uris.each |uri| { list.add(ObixObj { val = uri }) }
    return ObixObj { contract=Contract.watchIn; it.add(list) }
  }

  private ObixObj[] fromWatchOut(ObixObj res)
  {
    list := res.get("values")
    if (list.elemName != "list") throw Err("Expecting WatchOut.list to be <list>: $list")
    return list.list
  }

  private const Uri uri
  private const Uri leaseUri
  private const Uri addUri
  private const Uri removeUri
  private const Uri pollChangesUri
  private const Uri pollRefreshUri
  private const Uri deleteUri
}

