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

  override Void onGet()
  {
    uri := req.modRel
    if (uri == `xsl`) { onGetXsl; return }
    try
      respond(read(uri))
    catch (UnresolvedErr e)
      res.sendErr(404)
  }

  private Void onGetXsl()
  {
    file := ObixMod#.pod.file(`/res/xsl.xml`)
    FileWeblet(file).onGet
  }

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the ObixObj representation of the given URI for
  ** the application or return 'super.read' for default handling.
  ** The URI is relative to the ObixMod base - see `web::WebReq.modRel`
  ** Throw UnresolvedErr if URI doesn't map to a valid object.
  **
  virtual ObixObj read(Uri uri)
  {
    // {base} => lobby
    if (uri.path.size == 0) return lobby

    // {base}/about => about
    if (uri.path.size == 1 && uri.path[0] == "about") return about

    // doesn't exist
    throw UnresolvedErr(uri.toStr)
  }

  **
  ** Write the value for the given URI and return the new
  ** representation or return 'super.write' for default handling.
  ** The URI is relative to the ObixMod base - see `web::WebReq.modRel`
  ** Throw UnresolvedErr if URI doesn't map to a valid object.
  ** Throw ReadonlyErr if URI doesn't map to a writable object.
  **
  virtual ObixObj write(Uri uri, ObixObj val)
  {
    throw UnresolvedErr(uri.toStr)
  }

  **
  ** Invoke the operation for the given URI and return the
  ** result or return 'super.write' for default handling.  The
  ** URI is relative to the ObixMod base - see `web::WebReq.modRel`
  ** Throw UnresolvedErr if URI doesn't map to a valid operation.
  **
  virtual ObixObj invoke(Uri uri, ObixObj arg)
  {
    throw UnresolvedErr(uri.toStr)
  }

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

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Void respond(ObixObj obj)
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

}

