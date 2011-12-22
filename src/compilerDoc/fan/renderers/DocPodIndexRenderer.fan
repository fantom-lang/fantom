//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web

**
** Renders the index of a pod's documents.
**
** Index
** =====
**
**   <h1><span>pod</span>{pod.qname}</h1>
**   <p>{pod.summary}</p>
**
**   <h2>{section.name}</h2>
**   <table>
**    <tr>
**     <td>{type.name}</td>
**     <td>{type.summary}</td>
**    </tr>
**   </table>
**
** Table of Contents
** =================
**
**   <ul>
**    <li><a>...</a></li>
**    <li><a>...</a>
**     <ul>...</ul>
**    </li>
**   </ul>
**
class DocPodIndexRenderer : DocRenderer
{
  new make(DocEnv env, WebOutStream out, DocPodIndex doc)
    : super(env, out, doc)
  {
    this.index = doc
  }

  ** Pod index to render
  const DocPodIndex index

  ** Write the content for a pod index.  This delegates
  ** to `writeContentApi` or `writeContentManual`
  override Void writeContent()
  {
    if (index.pod.isManual)
      writeContentManual
    else
      writeContentApi
  }

  ** Write the content for an API (non-manual) pod
  virtual Void writeContentApi()
  {
    // type table
    pod := index.pod
    out.div("class='mainSidebar'")
    out.div("class='main type'")
    writeTypes
    out.divEnd

    // type list
    out.div("class='sidebar'")
    out.h3.w("All Types").h3End
    out.ul
    pod.types.each |t|
    {
      out.li
      writeLinkTo(t)
      out.liEnd
    }
    out.ulEnd
    out.divEnd
    out.divEnd

    // pod doc
    if (pod.podDoc != null)
    {
      // chapter
      out.div("class='mainSidebar'")
      out.div("class='main pod-doc' id='pod-doc'")
      DocChapterRenderer(env, out, pod.podDoc).writeBody
      out.divEnd

      // toc
      out.div("class='sidebar'")
      out.h3.w("Contents").h3End
      writePodDocToc(pod.podDoc.headings)
      out.divEnd
      out.divEnd
    }
  }

  ** Render the pod's index of types.
  virtual Void writeTypes()
  {
    // name
    pod := index.pod
    out.h1.span.w("pod").spanEnd.w(" $pod.name").h1End
    out.p.esc(pod.summary).pEnd

    // list type
    pod.index.toc.each |item,i|
    {
      if (item is Str)
      {
        if (i > 0) out.tableEnd
        out.h2.w(item).h2End
        out.table
      }
      else
      {
        type := item as DocType
        out.tr
        out.td; writeLinkTo(type); out.tdEnd
        out.td
        writeFandoc(type.doc.firstSentence)
        out.tdEnd
        out.trEnd
      }
    }
    out.tableEnd
  }

  ** Write out pod-doc table of contents.
  virtual Void writePodDocToc(DocHeading[] headings)
  {
    out.ul
    headings.each |h|
    {
      out.li.a(`#$h.anchorId`).esc(h.title).aEnd
      if (!h.children.isEmpty) writePodDocToc(h.children)
      out.liEnd
    }
    out.ulEnd
  }

  ** Write the content for a manual pod
  virtual Void writeContentManual()
  {
    // name
    pod := index.pod
    out.h1.w(pod.name).h1End
    out.p.esc(pod.summary).pEnd

    // contents
    out.div("class='toc'")
    open  := false
    pod.index.toc.each |item|
    {
      if (item is Str)
      {
        // close open list
        if (open) out.olEnd
        open = false

        // part header
        out.h2.esc(item).h2End
      }
      else
      {
        if (!open) out.ol
        open = true

        // chapter
        c := item as DocChapter
        out.li("value='$c.num'")
        writeLinkTo(c)
        out.p.esc(c.summary).pEnd
        out.p
        c.headings.each |h, i|
        {
          if (i > 0) out.w(", ")
          writeLinkTo(c, h.title, h.anchorId)
        }
        out.pEnd.liEnd
      }
    }
    if (open) out.olEnd
    out.divEnd
  }

}

