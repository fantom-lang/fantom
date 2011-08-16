//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web

**
** IndexRenderer renders the various indices:
**   - `writeTopIndex`: top level index of all pods
**   - `writeTypeIndex`: index of types in an API pod
**   - `writeChapterIndex`: index of chapters in a manual pod
**
class IndexRenderer : DocRenderer
{
  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out)
    : super(env, out)
  {
  }

  ** Render the HTML for top-level index of pods
  virtual Void writeTopIndex(DocPod[] pods)
  {
    writeStart("Doc Home")

    out.table
    pods.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd

    writeEnd
  }

  ** Render the HTML pod's index of types
  virtual Void writeTypeIndex(DocPod pod)
  {
    writeStart(pod.name)

    out.p.a(`../index.html`).w("Home").aEnd
      .w(" > ").a(`index.html`).w(pod.name).aEnd
    if (pod.podDoc != null)
      out.w(" | ").a(`pod-doc.html`).w("PodDoc").aEnd
    out.pEnd.hr

    out.h2.w("pod").h2End
    out.h1.w(pod.name).h1End
    out.p.esc(pod.summary).pEnd
    if (pod.podDoc != null)
      out.p.w("See <a href='pod-doc.html'>PodDoc</a> for more information.").pEnd

    out.table
    pod.types.each |type|
    {
      out.tr
        .td.a(`${type.name}.html`).w(type.name).aEnd.tdEnd
        .td.w(type.summary).tdEnd
        .trEnd
    }
    out.tableEnd

    writeEnd
  }

  ** Render the HTML pod's index of chapters
  virtual Void writeChapterIndex(DocPod pod)
  {
    out.p.a(`../index.html`).w("Home").aEnd.pEnd.hr

    writeStart(pod.name)

    out.h2.w("pod").h2End
    out.h1.w(pod.name).h1End
    out.p.w(pod.summary).pEnd

    out.table
    pod.chapterIndex.each |item|
    {
      if (item is Str)
      {
        // section header
        out.tr.td.b.w(item).bEnd.tdEnd.td.tdEnd.trEnd
      }
      else
      {
        name    := (Uri)item->get(0)
        summary := (Str)item->get(1)
        out.tr
          .td.a(`${name}.html`).w(name).aEnd.tdEnd
          .td.w(summary).tdEnd
        .trEnd
      }
    }
    out.tableEnd

    writeEnd
  }

}

