//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

using web

**
** DocEnv is the centralized glue class for managing documentation
** modeling and rendering:
**   - lookup and cache for pod/type model instances
**   - hooks for reflecting pods
**   - hooks for theming HTML chrome and navigation
**   - hooks for renderering HTML pages
**   - hooks for hyperlink resolution
**
class DocEnv
{

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  ** Used to discover and load DocPods and DocTypes
  DocLoader loader := DocLoader()

  ** `DocLinker` to use for resolving fandoc hyperlinks.  See `makeLinker`.
  Type linker := DocLinker#

  ** Plug-in for error reporting
  DocErrHandler errHandler := DocErrHandler()

//////////////////////////////////////////////////////////////////////////
// Factories
//////////////////////////////////////////////////////////////////////////

  ** Constructor a linker to use for given base object,
  ** link str and location.
  DocLinker makeLinker(Obj base, Str link, DocLoc loc)
  {
    func := Field.makeSetFunc([
      DocLinker#env:  this,
      DocLinker#base: base,
      DocLinker#link: link,
      DocLinker#loc:  loc])
    return linker.make([func])
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  ** Route error to `errHandler` and return as DocErr.
  DocErr err(Str msg, DocLoc loc, Err? cause := null)
  {
    errReport(DocErr(msg, loc, cause))
  }

  ** Route error to `errHandler` and return the specified DocErr.
  DocErr errReport(DocErr err)
  {
    errHandler.onErr(err)
    return err
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  ** Get a pod by name.  If not found return null or
  ** throw UnknownPodErr based on checked flag.
  DocPod? pod(Str podName, Bool checked := true)
  {
    pod := podCache[podName]
    if (pod == null)
    {
      pod = loader.findPod(this, podName)
      if (pod != null) podCache[podName] = pod
    }
    if (pod != null) return pod
    if (checked) throw UnknownPodErr(podName)
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str:DocPod podCache := [:]
}