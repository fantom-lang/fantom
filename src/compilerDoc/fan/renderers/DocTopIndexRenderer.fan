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
    writeManuals
    out.divEnd

    // apis
    out.div("class='apis'")
    writeApis
    out.divEnd

    // end
    out.divEnd
  }

  ** Write manuals index.
  virtual Void writeManuals()
  {
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    out.table
    index := (DocTopIndex)this.doc
    index.spaces.each |space|
    {
      pod := space as DocPod
      if (pod == null || !pod.isManual) return

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
    out.divEnd
  }

  ** Write API index.
  virtual Void writeApis()
  {
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    out.table
    index := (DocTopIndex)this.doc
    index.spaces.each |space|
    {
      pod := space as DocPod
      if (pod == null || pod.isManual) return
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd
    out.divEnd
  }
}

