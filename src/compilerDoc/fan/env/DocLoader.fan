//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

using web

**
** DocLoader is responsible for lazy loading:
**   - discovery off all pods in DocEnv
**   - loading DocPod
**
class DocLoader
{

  **
  ** Resolve the full listing of pod names to use for topindex
  ** and to populate `DocEnv.pods`.  Default implementation
  ** routes to `sys::Env.findAllPodNames`.
  **
  protected virtual Str[] findAllPodNames()
  {
    Env.cur.findAllPodNames
  }

  **
  ** Resolve a pod name to a DocPod or return null.  Default
  ** implementation routes to `findPodFile` and then calls
  ** `DocPod.load`.
  **
  protected virtual DocPod? findPod(DocEnv env, Str podName)
  {
    file := findPodFile(podName)
    if (file == null) return null
    return DocPod.load(env, file)
  }

  **
  ** Resolve a pod name to a File on the local file system.
  ** If not found return null.
  **
  protected virtual File? findPodFile(Str podName)
  {
    Env.cur.findPodFile(podName)
  }
}