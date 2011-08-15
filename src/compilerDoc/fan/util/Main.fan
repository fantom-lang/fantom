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

    // render topindex if requested
    if (all || topindex)
    {
      env.makeIndexRenderer(outDir.plus(`index.html`).out).writeTopIndex(env.pods)
    }

    // render each pod
    docPods.each |pod|
    {
      // pod index
      if (pod.chapters.isEmpty)
        env.makeIndexRenderer(outDir.plus(`${pod.name}/index.html`).out).writeTypeIndex(pod)
      else
        env.makeIndexRenderer(outDir.plus(`${pod.name}/index.html`).out).writeChapterIndex(pod)

      // pod-doc
      if (pod.podDoc != null)
        env.makeChapterRenderer(outDir.plus(`${pod.name}/pod-doc.html`).out, pod.podDoc).writeChapter

      // each type
      pod.types.each |type|
      {
        env.makeTypeRenderer(outDir.plus(`${pod.name}/${type.name}.html`).out, type).writeType
      }

      // each chapter
      pod.chapters.each |chapter|
      {
        env.makeChapterRenderer(outDir.plus(`${pod.name}/${chapter.name}.html`).out, chapter).writeChapter
      }
    }

    // if we collected any errrors assume failure
    ok := env.errHandler.errs.isEmpty
    return ok ? 0 : 1
  }

}