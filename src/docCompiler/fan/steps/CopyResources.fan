//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** CopyResources copies master resource files like fandoc.css
** to the target directory.
**
class CopyResources : DocCompilerStep
{

  new make(DocCompiler compiler, Pod pod, File outDir)
    : super(compiler)
  {
    this.pod = pod
    this.outDir = outDir
  }

  Void run()
  {
    exts := ["png", "gif", "jpg", "jpeg", "css", "js"]
    pod.files.each |File f|
    {
      if (exts.contains(f.ext ?: "")) copy(f)
    }
  }

  Void copy(File from)
  {
    to := outDir + from.uri.name.toUri

    log.debug("  Copy [$to]")

    to.create
    out := to.out
    from.in.pipe(out)
    out.close
  }

  Pod pod
  File outDir
}