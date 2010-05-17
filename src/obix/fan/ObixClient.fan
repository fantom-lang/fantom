//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 May 09  Brian Frank  Creation
//

using web

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

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Read an obix document with the specified href.
  **
  ObixObj read(Uri uri)
  {
    c := makeReq(uri, "GET")
    c.writeReq.readRes
    if (c.resCode != 200) throw IOErr("Bad HTTP response: $c.resCode $c.reqUri")
    return ObixObj.readXml(c.resIn)
  }

  **
  ** Write an obix document to the specified href and
  ** return the server's result.
  **
  ObixObj write(ObixObj obj) { post(obj.href, "PUT", obj) }

  **
  ** Invoke the operation identified by the specified href.
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
    c := makeReq(uri, method)
    c.writeReq
    in.writeXml(c.reqOut)
    c.reqOut.close
    c.readRes
    if (c.resCode == 100) c.readRes
    if (c.resCode != 200) throw IOErr("Bad HTTP response: $c.resCode")
    return ObixObj.readXml(c.resIn)
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

  ** Log for tracing
  //Log log := Log.get("obix")

  private Str authHeader
}