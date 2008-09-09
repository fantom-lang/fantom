//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

using web

**
** FindResourceStep is responsible for mapping the incoming the
** URI to a Fan object and setting the `web::WebReq.resource`
** field.
**
** See [docLib::WebApp]`docLib::WebApp#findResourceStep`
**
const class FindResourceStep : WebAppStep
{

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  **
  ** Perform this step against the specified request and response.
  **
  override Void service(WebReq req, WebRes res)
  {
    // attempt to find the resource
    uri := req.uri.pathOnly
    req.resource = find(uri)

    // not found
    if (req.resource == null) { res.sendError(404); return }

    // if resource is a dir, check for trailing slash
    checkDirSlash(req, res); if (res.isDone) return

    // if we found a directory, then map to index file
    file := req.resource as File
    if (file != null && file.isDir)
      req.resource = findDirIndex(file)
  }

  **
  ** Attempt to find the resource identified by the
  ** specified uri or return null if not found.
  **
  virtual Obj find(Uri uri)
  {
    // we only use path section
    uri = uri.pathOnly

    // check if this is the home page
    if (uri.path.isEmpty)
    {
      obj := resolve(homePage)
      if (obj == null) log.warn("Invalid FindResourceStep.homePage: $homePage")
      return obj
    }

    // map uri to the VM's namespace
    obj := resolve(uri)
    if (obj != null) return obj

    // if we still haven't found it, then search
    // the list of configured extensions
    return findExtSearch(uri)
  }

  **
  ** Search the configured list of extensions in `extSearch` to
  ** map the web uri to a resource in the local VM's namespace.
  **
  virtual Obj findExtSearch(Uri uri)
  {
    if (extSearch != null)
    {
      Obj match := null
      found := extSearch.any |Str ext->Bool|
      {
        extUri := (uri.toStr + "." + ext).toUri
        match = resolve(extUri)
        return match != null
      }
      if (found) return match
    }
    return null
  }

  **
  ** If a directory is being accessed without a trailing
  ** slash, then redirect to the normalized uri.  A directory
  ** is defined as any object with a "isDir" method which
  ** returns true.
  **
  virtual Void checkDirSlash(WebReq req, WebRes res)
  {
    // if the uri already ends in slash, no problemo
    uri := req.uri
    obj := req.resource
    if (uri.isDir) return

    // check if directory
    m := obj.type.slot("isDir", false) as Method
    if (m == null || !m.params.isEmpty) return
    if (m.callOn(obj, null) != true) return

    // we have dir with no slash here, so redirect
    res.redirect(uri.plusSlash)
  }

  **
  ** Given a directory file, map to a resource which serves
  ** as its "index".  The standard implementation searches the
  ** filenames configured in `dirIndex`.
  **
  virtual Obj findDirIndex(File dir)
  {
    if (dirIndex != null)
    {
      File index := null
      found := dirIndex.any |Uri f->Bool|
      {
        index = dir + f
        return index.exists
      }
      if (found) return index
    }
    return dir
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Uri of home page resource to for requests to "/".
  **
  const Uri homePage := `/homePage`

  **
  ** List extensions to search when resolving the
  ** web Uri to the namespace Uri.
  **
  const Str[] extSearch := ["fan", "html"]

  **
  ** List of file names to search for to map a File
  ** directory to a resource.
  **
  const Uri[] dirIndex := [`index.html`]

}
