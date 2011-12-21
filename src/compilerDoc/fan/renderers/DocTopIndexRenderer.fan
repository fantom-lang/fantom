//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web

**
** Renders the index of a pod's documents
**
class DocTopIndexRenderer : DocRenderer
{
  new make(DocEnv env, WebOutStream out, DocTopIndex doc)
    : super(env, out, doc)
  {
    this.index = doc
  }

  ** Pod index to render
  const DocTopIndex index

  ** Write the content for a top index.  Default
  ** organizes pods into manuals and APIs.
  override Void writeContent()
  {
    // start
    out.div("class='index'")

    // manuals
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    writeManuals(index.pods.findAll |p| { p.isManual })
    out.divEnd

    // apis
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    writeApis(index.pods.findAll |p| { !p.isManual })
    out.divEnd

    // end
    out.divEnd
  }

  ** Write manuals table of pod name/links along with
  ** shortcut chapter links.
  virtual Void writeManuals(DocPod[] pods)
  {
    out.table
    index := (DocTopIndex)this.doc
    pods.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary)
        .div
        pod.chapters.each |ch,i|
        {
          if (i > 0) out.w(", ")
          out.a(`${pod.name}/${ch.name}.html`).w("$ch.name").aEnd
        }
        out.divEnd
        out.tdEnd
     out.trEnd
    }
    out.tableEnd
  }

  ** Write API table of pod name/link and summaries.
  virtual Void writeApis(DocPod[] pods)
  {
    out.table
    index := (DocTopIndex)this.doc
    pods.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd
  }
}

