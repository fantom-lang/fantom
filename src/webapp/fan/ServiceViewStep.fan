//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

using web

**
** ServiceViewStep routes to the view which has been
** stashed in the "webapp.view" thread local.
**
** See [docLib::WebApp]`docLib::WebApp#serviceViewStep`
**
const class ServiceViewStep : WebAppStep
{

  **
  ** Perform this step against the specified request and response.
  **
  override Void service(WebReq req, WebRes res)
  {
    Weblet? view := req.stash["webapp.view"]
    if (view == null) throw Err("req.stash[webapp.view] is null")
    view.service
  }

}