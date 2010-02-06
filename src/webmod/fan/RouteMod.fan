//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 08  Brian Frank  Creation
//

using web

**
** RouteMod routes a level of the URI path to sub-WebMods.
**
** See [pod doc]`pod-doc#route`
**
const class RouteMod : WebMod
{
  **
  ** Constructor with it-block.
  **
  new make(|This|? f)
  {
    f?.call(this)
    if (routes.isEmpty) throw ArgErr("RouteMod.routes is empty")
  }

  **
  ** Map of URI path names to sub-WebMods.  The name "index"
  ** is used for requests to the RouteMod itself.
  **
  const Str:WebMod routes := Str:WebMod[:]

  override Void onService()
  {
    // get the next name in the path
    name := req.modRel.path.first

    // lookup route, if not found this is 404
    route := routes[name ?: "index"]
    if (route == null) { res.sendErr(404); return }

    // dive into sub-WebMode
    req.mod = route
    if (name != null) req.modBase = req.modBase + `$name/`
    route.onService
  }

  **
  ** Call 'onStart' on sub-mods.
  **
  override Void onStart() { routes.each |mod| { mod.onStart } }

  **
  ** Call 'onStop' on sub-mods.
  **
  override Void onStop() { routes.each |mod| { mod.onStop } }

}