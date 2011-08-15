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

  ** Theme instance to use for HTML chrome and navigation
  DocTheme theme := DocTheme()

  ** Type to use for rendering type various index pages (top, pod, etc)
  Type indexRenderer := IndexRenderer#

  ** Type to use for rendering type API HTML pages
  Type typeRenderer := TypeRenderer#

  ** Plug-in for error reporting
  DocErrHandler errHandler := DocErrHandler()

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

  ** List all pods found in this environment.
  once DocPod[] pods()
  {
    acc := DocPod[,]
    loader.findAllPodNames.each |name| { acc.add(pod(name)) }
    acc.sort |a, b| { a.name <=> b.name }
    return acc.ro
  }

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