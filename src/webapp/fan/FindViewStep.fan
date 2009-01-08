//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

using web

**
** FindViewStep is responsible for finding a suitable Weblet
** used to process the source and sticking it in the WebReq.stash
** under "webapp.view".
**
** See [docLib::WebApp]`docLib::WebApp#findViewStep`
**
const class FindViewStep : WebAppStep
{

  **
  ** Perform this step against the specified request and response.
  **
  override Void service(WebReq req, WebRes res)
  {
    // if the view is explicitly specified
    // TODO: should we restrict to typedb matches?
    explicit := req.uri.query["view"]
    if (explicit != null)
    {
      try
      {
        view := (Weblet)Type.find(explicit).make
        req.stash["webapp.view"] = view
        return
      }
      catch (Err e)
      {
        log.warn("Explicit view $explicit not found", e)
        res.sendError(404)
        return
      }
    }

    // if this resouce is Weblet, instanciate it and use it directly
    if (req.resource is Type && req.resource->fits(Weblet#))
      req.resource = req.resource->make

    // if resource is itself a Weblet, then it is its own view
    if (req.resource is Weblet)
    {
      req.stash["webapp.view"] = req.resource
      return
    }

    // use typedb to match resource type to weblet type
    viewTypes := Type.findByFacet("webView", req.resource.type, true)
    if (viewTypes.isEmpty)
    {
      log.warn("No view available for $req.resource.type")
      res.sendError(404)
      return
    }

    // if there is more than one, then find the highest priority
    viewType := viewTypes.first
    if (viewTypes.size > 1)
    {
      max := 0
      viewTypes.each |Type vt|
      {
        Int priority := vt.facet("webViewPriority", 0)
        if (priority > max) viewType = vt
      }
    }

    // init view instance
    view := viewType.make
    if (view isnot Weblet)
    {
      log.warn("View type $view.type for $req.resource.type is not Weblet")
      res.sendError(404)
      return
    }

    req.stash["webapp.view"] = view
  }


}