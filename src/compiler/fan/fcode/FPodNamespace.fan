//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//   29 Aug 06  Brian Frank  Ported from Java to Fan
//

**
** FPodNamespace implements Namespace by reading the fcode
** from pods directly.  Its not as efficient as using reflection,
** but lets us compile against a different pod set.
**
class FPodNamespace : CNamespace
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make a FPod namespace which looks in the
  ** specified directory to resolve pod files.
  **
  new make(File dir)
  {
    this.dir = dir
    this.pods = Str:FPod[:]
    init
  }

//////////////////////////////////////////////////////////////////////////
// CNamespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Map to an FPod
  **
  override FPod? resolvePod(Str podName, Bool checked)
  {
    // check cache
    fpod := pods[podName]
    if (fpod != null) return fpod

    // try to find it
    file := dir + (podName + ".pod").toUri
    if (!file.exists)
    {
      if (checked) throw UnknownPodErr.make(podName)
      return null
    }

    // load it and stash in the cache
    fpod = FPod.make(this, podName, Zip.open(file))
    fpod.read
    pods[podName] = fpod
    return fpod
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly File dir       // where we look for pod files
  private Str:FPod pods   // keyed by pod name

}