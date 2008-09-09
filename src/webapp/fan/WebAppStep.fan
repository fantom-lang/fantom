//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

using web

**
** WebAppStep is the base class for web application steps.
**
abstract const class WebAppStep : WebStep
{

  **
  ** Resolve a Uri to a resource object or return null.
  ** If the resource is a script file ending in ".fan",
  ** then is compiled and an instance of the primary type
  ** is returned.
  **
  Obj resolve(Uri uri)
  {
    // if uri is null, return null
    if (uri == null) return null

    // map uri to local namespace
    obj := Sys.ns.get(uri, false)
    if (obj == null) return null

    // if script file, then compile it to
    // a type and create instance of that type
    f := obj as File
    if (f != null && f.ext == "fan")
      return Sys.compile(f).make

    return obj
  }

  ** Web app logging
  const static Log log := Log("webapp")

}
