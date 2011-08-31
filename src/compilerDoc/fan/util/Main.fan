//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using util
using web

**
** Main
**
class Main : AbstractMain
{

  @Opt { help = "Generate top index" }
  Bool topindex

  @Opt { help = "Generate everything (topindex and all pods)" }
  Bool all

  @Arg { help = "Name of pods to compile" }
  Str[] pods := [,]

  @Opt { help = "Output dir for doc files" }
  File outDir := Env.cur.workDir + `doc/`

  override Int run()
  {
    // must generate topindex or at least one pod
    if (!topindex && !all && pods.isEmpty) { usage; return 1 }

    // create default DocEnv instance
    env := DocEnv()

    // figure out which pods to render
    DocPod[] docPods := all ? env.pods : pods.map |n->DocPod| { env.pod(n) }

    // render pods
    docWriter := FileDocWriter
    {
      it.env    = env
      it.pods   = docPods
      it.index  = all || topindex
      it.outDir = this.outDir
    }
    return docWriter.write.isEmpty ? 0 : 1
  }
}