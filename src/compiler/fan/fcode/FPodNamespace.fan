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
  new make(Compiler c, File dir)
    : super(c)
  {
    this.dir = dir
    init
  }

//////////////////////////////////////////////////////////////////////////
// CNamespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Map to an FPod
  **
  protected override FPod? findPod(Str podName)
  {
    // try to find it
    file := dir + (podName + ".pod").toUri
    if (!file.exists) return null

    // load it
    fpod := FPod.make(this, podName, Zip.open(file))
    fpod.read
    return fpod
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly File dir       // where we look for pod files

}