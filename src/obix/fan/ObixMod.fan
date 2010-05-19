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
**   {modBase}/xsl     debug style sheet
**   {modBase}/about   about object
**   {modBase}/batch   batch operation
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
    cmd := uri.path.getSafe(0)
    switch (cmd)
    {
      case null:    onLobby; return
      case "about": onAbout; return
      case "xsl":   onXsl;   return
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
      res.sendErr(404)
      return
    }
    catch (Err e)
    {
      e.trace
      res.sendErr(500, e.traceToStr)
      return
    }

    // return response
    writeResObj(result)
  }

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
      contract = Contract("obix:Lobby")
      ObixObj { elemName = "ref"; name = "about"; href=`about/` },
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
      contract = Contract("obix:About")
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

  private const Str aboutServerName
  private const Str aboutVendorName
  private const Uri aboutVendorUrl
  private const Str aboutProductName
  private const Str aboutProductVer
  private const Uri aboutProductUrl

}

