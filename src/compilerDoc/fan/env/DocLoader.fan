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
  virtual Str[] findAllPodNames()
  {
    Env.cur.findAllPodNames
  }

  **
  ** Resolve a pod name to a DocPod or return null if not found.
  ** Default implementation routes to `findPodFile`.  The
  ** returned pod only needs to have its summary meta loaded,
  ** the types will be lazily loaded by `loadPod`.
  **
  virtual DocPod? findPod(DocEnv env, Str podName)
  {
    file := findPodFile(podName)
    if (file == null) return null
    zip := Zip.open(file)
    try
    {
      meta := zip.contents[`/meta.props`] ?: throw Err("Pod missing meta.props: $file")
      return DocPod(env, meta.readProps)
    }
    finally zip.close
  }

  **
  ** Resolve a pod name to a File on the local file system or if
  ** not found return null.  This method is used by both `findPod`
  ** and `loadPod` for file system loaders.
  **
  virtual File? findPodFile(Str podName)
  {
    Env.cur.findPodFile(podName)
  }
}