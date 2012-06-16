//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   17 May 10  Brian Frank  Creation
//

using web

**
** ObixMod is an abstract base class that implements the
** standard plumbing for adding oBIX server side support.
** Standardized URIs handled by the base class:
**
**   {modBase}/xsl           debug style sheet
**   {modBase}/about         about object
**   {modBase}/batch         batch operation
**   {modBase}/watchService  watch service
**   {modBase}/watch/{id}    watch
**
** All other URIs to the mod are automatically handled
** by the following callbacks:
**  - GET: `onRead`
**  - PUT: `onWrite`
**  - POST: `onInvoke`
**
const abstract class ObixMod : WebMod
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with the given map for 'obix:About' parameters:
  **   - serverName: defaults to 'Env.cur.host'
  **   - vendorName: defaults to "Fantom"
  **   - vendorUrl: defaults to "http://fantom.org/"
  **   - productName: defaults to "Fantom"
  **   - productVersion: defaults to version of obix pod
  **   - productUrl: defaults to "http://fantom.org/"
  **
  new make(Str:Obj about := Str:Obj[:])
  {
    this.aboutServerName  = about["serverName"]     ?: Env.cur.host
    this.aboutVendorName  = about["vendorName"]     ?: "Fantom"
    this.aboutVendorUrl   = about["vendorUrl"]      ?: `http://fantom.org`
    this.aboutProductName = about["productName"]    ?: "Fantom"
    this.aboutProductVer  = about["productVersion"] ?: ObixMod#.pod.version.toStr
    this.aboutProductUrl  = about["productUrl"]     ?: `http://fantom.org`
  }

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  override Void onService()
  {
    // handle special built-in URIs
    uri := req.modRel
    try
    {
      cmd := uri.path.getSafe(0)
      switch (cmd)
      {
        case null:           onLobby; return
        case "about":        onAbout; return
        case "batch":        onBatch; return
        case "watchService": onWatchService; return
        case "watch":        onWatch; return
        case "xsl":          onXsl; return
      }
    }
    catch (Err e)
    {
      result := ObixErr.toObj("Internal error: $e.toStr", e)
      writeResObj(result)
      return
    }

    ObixObj? result
    try
    {

      // route to callback
      switch (req.method)
      {
        case "GET":  result = onRead(uri)
        case "PUT":  result = onWrite(uri, readReqObj)
        case "POST": result = onInvoke(uri, readReqObj)
        default:     res.sendErr(501); return
      }
    }
    catch (UnresolvedErr e)
    {
      result = ObixErr.toUnresolvedObj(uri)
    }
    catch (Err e)
    {
      result = ObixErr.toObj("Internal error: $e.toStr", e)
    }

    // return response
    writeResObj(result)
  }

//////////////////////////////////////////////////////////////////////////
// Predefined Objects/URIs
//////////////////////////////////////////////////////////////////////////

  private Void onLobby()
  {
    if (req.method != "GET") { res.sendErr(501); return }
    writeResObj(lobby)
  }

  private Void onAbout()
  {
    if (req.method != "GET") { res.sendErr(501); return }
    writeResObj(about)
  }

  private Void onXsl()
  {
    file := ObixMod#.pod.file(`/res/xsl.xml`)
    FileWeblet(file).onService
  }

//////////////////////////////////////////////////////////////////////////
// Batch
//////////////////////////////////////////////////////////////////////////

  private Void onBatch()
  {
    // must be invoke POST
    if (req.method != "POST") { res.sendErr(501); return }

    // read input which must be <list>
    in := readReqObj
    if (in.elemName != "list") { writeResErr("Expecting BatchIn to be <list>"); return }

    // process each list input operation and add item to output list
    out := ObixObj { elemName="list"; contract=Contract.batchOut }
    in.each |opIn|
    {
      // process a single input operation
      Uri? opUri := ``
      ObixObj? opOut
      try
      {
        // ensure we have a uri value
        if (opIn.elemName != "uri") throw Err("Batch op must be <uri>")
        opUri = opIn.val as Uri
        if (opUri == null) throw Err("Batch op missing <uri> val")

        // relative to mod
        normUri := opUri
        uriStr := normUri.toStr
        baseStr := req.modBase.toStr
        if (uriStr.startsWith(baseStr))
          normUri = uriStr[baseStr.size..-1].toUri

        switch (opIn.contract.toStr)
        {
          case "obix:Read":    opOut = onRead(normUri)
          case "obix:Write":   opOut = onWrite(normUri, opIn.get("in"))
          case "obix:Invoke":  opOut = onInvoke(normUri, opIn.get("in"))
          default:             opOut = ObixErr.toObj("Unknown batch op type: $opIn.contract")
        }
      }
      catch (UnresolvedErr e)  opOut = ObixErr.toUnresolvedObj(opUri)
      catch (Err e)            opOut = ObixErr.toObj("Failed: $opIn", e)

      // add this op output to the overall output list
      opOut.href = opUri
      out.add(opOut)
    }

    return writeResObj(out)
  }

//////////////////////////////////////////////////////////////////////////
// Watches
//////////////////////////////////////////////////////////////////////////

  private Void onWatchService()
  {
    // watchService/
    uri := req.modRel
    if (uri.path.size == 1)
    {
      if (req.method != "GET") { res.sendErr(501); return }
      writeResObj(watchService)
      return
    }

    // watchService/make
    if (uri.path.size == 2 && uri.path[1] == "make")
    {
      if (req.method != "POST") { res.sendErr(501); return }
      watch := watchOpen
      writeResWatch(watch)
      return
    }

    // anything else is unresolved error
    writeResUnresolvedErr
  }

  private Void onWatch()
  {
    // all URIs must resolve to active watch
    uri := req.modRel
    watch := watch(uri.path.getSafe(1) ?: "?")
    if (watch == null) { writeResUnresolvedErr; return }

    // /watch/{id} returns watch itself
    if (uri.path.size == 2) { writeResWatch(watch); return }

    // handle /watch/{id}/{cmd}
    cmd := uri.path.getSafe(2) ?: ""
    if (cmd == "pollChanges") { onWatchPollChanges(watch); return }
    if (cmd == "pollRefresh") { onWatchPollRefresh(watch); return }
    if (cmd == "lease")       { onWatchLease(watch); return }
    if (cmd == "add")         { onWatchAdd(watch); return }
    if (cmd == "remove")      { onWatchRemove(watch); return }
    if (cmd == "delete")      { onWatchDelete(watch); return }

    // anything else is unresolved error
    writeResUnresolvedErr
  }

  private Void onWatchLease(ObixModWatch watch)
  {
    // if write
    if (req.method == "PUT")
    {
      val := readReqObj.val
      if (val isnot Duration) throw Err("Expected lease val to be reltime, not $val")
      watch.lease = val
    }

    // if read/write
    if (req.method == "GET" || req.method == "PUT")
    {
      writeResObj(ObixObj { name="lease"; href=watchUri(watch)+`lease`; val = watch.lease })
      return
    }

    res.sendErr(501)
  }

  private Void onWatchAdd(ObixModWatch watch)
  {
    if (req.method != "POST") { res.sendErr(501); return }
    uris := readWatchIn
    objs := watch.add(uris)
    writeWatchOut(objs)
  }

  private Void onWatchRemove(ObixModWatch watch)
  {
    if (req.method != "POST") { res.sendErr(501); return }
    uris := readWatchIn
    watch.remove(uris)
    writeResObj(ObixObj { val="Watch removed: $uris.size" })
  }

  private Void onWatchPollChanges(ObixModWatch watch)
  {
    if (req.method != "POST") { res.sendErr(501); return }
    readReqObj // ignored
    objs := watch.pollChanges
    writeWatchOut(objs)
  }

  private Void onWatchPollRefresh(ObixModWatch watch)
  {
    if (req.method != "POST") { res.sendErr(501); return }
    readReqObj // ignored
    objs := watch.pollRefresh
    writeWatchOut(objs)
  }

  private Void onWatchDelete(ObixModWatch watch)
  {
    if (req.method != "POST") { res.sendErr(501); return }
    watch.delete
    writeResObj(ObixObj { val="Watch deleted: $watch.id" })
  }

  private Uri[] readWatchIn()
  {
    // read input which must be <list>
    obj := readReqObj
    list := obj.get("hrefs")
    if (list.elemName != "list") throw Err("Expecting WatchIn.hrefs to be <list>")

    // process each list input operation and add item to output list
    acc := Uri[,]
    list.each |kid|
    {
      uri := kid.val as Uri
      if (uri == null) throw Err("Expecting WatchIn child to be <uri>")
      acc.add(uri)
    }
    return acc
  }

  private Void writeWatchOut(ObixObj[] objs)
  {
    list := ObixObj { elemName="list"; name="values" }
    objs.each |obj|
    {
      if (obj.href == null) throw Err("Watched obj missing href: $obj")
      list.add(obj)
    }
    writeResObj(ObixObj {
        contract = Contract.watchOut
        href = req.absUri + req.modBase
        add(list) })
  }

  private Void writeResWatch(ObixModWatch watch)
  {
    obj := watch.toObixObj()
    obj.href = watchUri(watch)
    writeResObj(obj)
  }

  private Uri watchUri(ObixModWatch watch)
  {
    req.modBase + `watch/$watch.id/`
  }

//////////////////////////////////////////////////////////////////////////
// Read/Write ObixObj
//////////////////////////////////////////////////////////////////////////

  private ObixObj readReqObj()
  {
    str := req.in.readAllStr
    return ObixObj.readXml(str.in)
  }

  private Void writeResObj(ObixObj obj)
  {
    buf := Buf()
    out := buf.out
    out.print("<?xml version='1.0' encoding='UTF-8'?>\n")
    out.print("<?xml-stylesheet type='text/xsl' href='").print(req.modBase).print("xsl'?>\n")
    obj.writeXml(out)
    buf.flip

    res.headers["Content-Type"] = "text/xml"
    res.headers["Content-Length"] = buf.size.toStr
    res.out.writeBuf(buf)
    res.out.close
  }

  private Void writeResErr(Str msg, Err? cause := null)
  {
    writeResObj(ObixErr.toObj(msg, cause))
  }

  private Void writeResUnresolvedErr()
  {
    writeResObj(ObixErr.toUnresolvedObj(req.modRel))
  }

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the ObixObj representation of the given URI for
  ** the application.  The URI is relative to the ObixMod
  ** base - see `web::WebReq.modRel`.  Throw UnresolvedErr
  ** if URI doesn't map to a valid object.  The resulting
  ** object must have its href set to the proper absolute
  ** URI according to 5.2 of the oBIX specification.
  **
  abstract ObixObj onRead(Uri uri)

  **
  ** Write the value for the given URI and return the new
  ** representation.  The URI is relative to the ObixMod
  ** base - see `web::WebReq.modRel`.  Throw UnresolvedErr if URI
  ** doesn't map to a valid object.  Throw ReadonlyErr if
  ** URI doesn't map to a writable object.
  **
  abstract ObixObj onWrite(Uri uri, ObixObj val)

  **
  ** Invoke the operation for the given URI and return the result.
  ** The URI is relative to the ObixMod base - see `web::WebReq.modRel`
  ** Throw UnresolvedErr if URI doesn't map to a valid operation.
  **
  abstract ObixObj onInvoke(Uri uri, ObixObj arg)

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Get represenation of the Lobby object.  Subclasses
  ** can override this to customize their lobby.
  **
  virtual ObixObj lobby()
  {
    ObixObj
    {
      href = req.absUri.plusSlash
      contract = Contract.lobby
      ObixObj { elemName = "ref"; name = "about"; href=`about/`; contract=Contract.about },
      ObixObj { elemName = "op";  name = "batch"; href=`batch/`; in=Contract.batchIn; out=Contract.batchOut},
      ObixObj { elemName = "ref"; name = "watchService"; href=`watchService/`; contract=Contract.watchService },
    }
  }

  **
  ** Get represenation of the About object.  Subclasses should
  ** override this to customize their about.  See `make` to
  ** customize vendor and product fields.
  **
  virtual ObixObj about()
  {
    ObixObj
    {
      href = req.absUri.plusSlash
      contract = Contract.about
      ObixObj { name = "obixVersion";    val = "1.1" },
      ObixObj { name = "serverName";     val = aboutServerName },
      ObixObj { name = "serverTime";     val = DateTime.now },
      ObixObj { name = "serverBootTime"; val = DateTime.boot },
      ObixObj { name = "vendorName";     val = aboutVendorName },
      ObixObj { name = "vendorUrl";      val = aboutVendorUrl },
      ObixObj { name = "productName";    val = aboutProductName },
      ObixObj { name = "productVersion"; val = aboutProductVer},
      ObixObj { name = "productUrl";     val = aboutProductUrl },
      ObixObj { name = "tz";             val = TimeZone.cur.fullName },
    }
  }

  **
  ** Get represenation of the WatchService object.  Subclasses
  ** can override this to customize their watch service.
  **
  virtual ObixObj watchService()
  {
    ObixObj
    {
      href = req.absUri.plusSlash
      contract = Contract.watchService
      ObixObj { elemName = "op"; name = "make"; href=`make/`; out=Contract.watch },
    }
  }

  **
  ** Construct a new watch.
  **
  abstract ObixModWatch watchOpen()

  **
  ** Find an existing watch by its identifier or return null.
  **
  abstract ObixModWatch? watch(Str id)

  private const Str aboutServerName
  private const Str aboutVendorName
  private const Uri aboutVendorUrl
  private const Str aboutProductName
  private const Str aboutProductVer
  private const Uri aboutProductUrl

}

**************************************************************************
** ObixModWatch
**************************************************************************

**
** ObixMod hooks for implementing server side watches.  ObixMod manages
** the networking/protocol side of things, but subclasses are responsible
** for managing the actual URI subscription list and polling.
**
abstract class ObixModWatch
{
  ** Get unique idenifier for the watch. This string must be safe to
  ** use within a URI path (should not contain special chars or slashes)
  abstract Str id()

  ** Get/set lease time
  abstract Duration lease

  ** Add the given uris to watch and return current state.  If
  ** there is an error for an individual uri, return an error object.
  ** Resulting objects must have hrefs which exactly match input uri.
  abstract ObixObj[] add(Uri[] uris)

  ** Remove the given uris from the watch.  Silently ignore bad uris.
  abstract Void remove(Uri[] uris)

  ** Poll URIs which have changed since last poll.
  ** Resulting objects must have hrefs which exactly match input uri.
  abstract ObixObj[] pollChanges()

  ** Poll all URIs in this watch.
  ** Resulting objects must have hrefs which exactly match input uri.
  abstract ObixObj[] pollRefresh()

  ** Handle delete/cleanup of watch.
  abstract Void delete()

  ** Map  server side representation to its on-the-wire Obix representation.
  virtual ObixObj toObixObj()
  {
    ObixObj {
      it.elemName = "obj"
      it.contract = Contract.watch

      ObixObj { elemName="reltime"; name="lease";  href=`lease`; val = lease; writable=false },

      ObixObj { elemName="op"; name="add";         href=`add`;         in=Contract.watchIn; out=Contract.watchOut },
      ObixObj { elemName="op"; name="remove";      href=`remove`;      in=Contract.watchIn},
      ObixObj { elemName="op"; name="pollChanges"; href=`pollChanges`; out=Contract.watchOut},
      ObixObj { elemName="op"; name="pollRefresh"; href=`pollRefresh`; out=Contract.watchOut},
      ObixObj { elemName="op"; name="delete";      href=`delete` },
    }
  }

  ** Debug string
  override Str toStr() { "ObixModWatch $id" }
}