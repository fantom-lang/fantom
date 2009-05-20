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
    this.lobbyUri = lobby
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

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if this client does not have an open session.
  **
  readonly Bool isClosed := true

  **
  ** Open a session to the oBIX server.
  **
  Void open()
  {
    if (!isClosed) return
    isClosed = false
    lobby := read(lobbyUri)
    aboutUri = lobby.get("about").normalizedHref
    batchUri = lobby.get("batch").normalizedHref
    watchMakeUri = read(lobby.get("watchService").normalizedHref).get("make").normalizedHref
  }

  **
  ** Close the session to the oBIX server.
  ** Do nothing if session not open closed.
  **
  Void close()
  {
    if (isClosed) return
    isClosed = true
    aboutUri = null
    batchUri = null
    watchMakeUri = null
  }

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Read an obix document with the specified href.
  **
  ObixObj read(Uri uri)
  {
    checkOpen
    c := makeReq(uri, "GET")
    c.writeReq.readRes
    if (c.resCode != 200) throw IOErr("Bad HTTP response: $c.resCode")
    return ObixObj.readXml(c.resIn)
  }

  **
  ** Read about object.
  **
  ObixObj readAbout()
  {
    checkOpen
    if (aboutUri == null) throw Err("Missing URI for about")
    return read(aboutUri)
  }

  **
  ** Write an obix document to the specified href and
  ** return the server's result.
  **
  ObixObj write(ObixObj obj)
  {
    checkOpen
    throw UnsupportedErr("not done yet")
  }

  **
  ** Invoke the operation identified by the specified href.
  **
  ObixObj invoke(Uri uri, ObixObj in)
  {
    checkOpen
    throw UnsupportedErr("not done yet")
  }

  private Void checkOpen()
  {
    if (isClosed) throw Err("ObixClient is closed: $lobbyUri")
  }

  private WebClient makeReq(Uri uri, Str method)
  {
    uri = lobbyUri + uri
    c := WebClient(uri)
    c.reqMethod = method
    c.reqHeaders["Content-Type"]  = "text/xml; charset=utf-8"
    c.reqHeaders["Authorization"] = authHeader
    return c
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  static Void main(Str[] args)
  {
    c := ObixClient(args[0].toUri, "", "")
    c.open
    about := c.readAbout
    about.writeXml(Sys.out)
    echo(about->serverName)
    echo(about->vendorName)
    echo(about->productName)
    echo(about->productVersion)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Log for tracing
  Log log := Log.get("obix")

  private Str authHeader
  private Uri? aboutUri
  private Uri? batchUri
  private Uri? watchMakeUri

}