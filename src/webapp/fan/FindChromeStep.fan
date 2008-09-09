//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Mar 08  Andy Frank  Creation
//

using web

**
** FindChromeStep is responsible for finding a chrome `Widget` used
** to theme the target view.  If the current 'webapp.view' is not a
** `Widget`, this step does nothing.
**
** If a chrome is found, then the chrome widget replaces 'webapp.view',
** and the old view is stored in the [stash]`web::WebReq.stash` as
** 'webapp.chromeView'.  It's the chrome's responsiblity to then call
** service on the 'chromeView'.
**
** See [docLib::WebApp]`docLib::WebApp#findChromeStep`
**
const class FindChromeStep : WebAppStep
{
  **
  ** Perform this step against the specified request and response.
  **
  override Void service(WebReq req, WebRes res)
  {
    view := req.stash["webapp.view"]
    if (view is Widget)
    {
      chrome := find(req, res)
      if (chrome != null)
      {
        // move old view to chromeView, and set view to chrome
        req.stash["webapp.chromeView"] = view
        req.stash["webapp.view"] = chrome
      }
    }
  }

  **
  ** Return the chrome to use for this request, or null
  ** for no chrome.  Default implementation tries to find
  ** a Widget at `chrome`.
  **
  virtual Widget find(WebReq req, WebRes res)
  {
    if (chrome == null) return null
    obj := resolve(chrome)
    w := (obj is Type ? obj->make : obj) as Widget
    if (w == null) log.warn("Invalid FindChromeStep.chrome: $chrome")
    return w
  }

  **
  ** Uri to the default chrome, or null for no chrome.
  **
  const Uri chrome

}
