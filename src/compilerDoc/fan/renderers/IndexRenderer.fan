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
**   - `writeTypeIndex`: index of types in an API pod
**   - `writeChapterIndex`: index of chapters in a manual pod
**
class IndexRenderer : DocRenderer
{
  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out, DocPod pod)
    : super(env, out)
  {
    this.pod = pod
  }

  ** Pod to renderer
  DocPod pod { private set }

  ** Render the HTML pod's index of types
  virtual Void writeTypeIndex()
  {
    // name
    out.h1.span.w("pod").spanEnd.w(" $pod.name").h1End
    out.p.esc(pod.summary).pEnd

    // list type
    pod.toc.each |item,i|
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
          .td.a(`${type.name}.html`).w(type.name).aEnd.tdEnd
          .td.esc(type.summary).tdEnd
          .trEnd
      }
    }
    out.tableEnd
  }

  ** Write out pod-doc table of contents.
  virtual Void writePodDocToc(DocHeading[] headings := pod.podDoc.headings)
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

  ** Render the HTML pod's index of chapters
  virtual Void writeChapterIndex()
  {
    // name
    out.h1.w(pod.name).h1End
    out.p.esc(pod.summary).pEnd

    // contents
    out.div("class='toc'")
    open  := false
    pod.toc.each |item|
    {
      if (item is Str)
      {
        // close open list
        if (open) out.olEnd
        open = false

        // section header
        out.h2.esc(item).h2End
      }
      else
      {
        if (!open) out.ol
        open = true

        // chapter
        c := item as DocChapter
        list := c.headings.join(", ") |h| {
          "<a href='${c.name}.html#$h.anchorId'>$h.title.toXml</a>"
        }
        out.li("value='$c.num'")
          .a(`${c.name}.html`).esc(c.name).aEnd
          .p.esc(c.summary).pEnd
          .p.w(list).pEnd
          .liEnd
      }
    }
    if (open) out.olEnd
    out.divEnd
  }

  ** Write out chapter table of contents for pod.
  virtual Void writeChapterToc(DocChapter? cur := null)
  {
    // map chapters into sections
    map  := Str:DocChapter[][:] { ordered=true }
    last := ""
    pod.toc.each |item|
    {
      if (item is Str) last = item
      else
      {
        list := map[last] ?: DocChapter[,]
        list.add(item)
        map[last] = list
      }
    }

    // write list
    map.each |chapters, section|
    {
      // section header if defined
      if (!section.isEmpty)
      {
        if (cur != null && chapters.contains(cur))
        {
          // section header
          out.p.esc(section).pEnd
        }
        else
        {
          // skip chapters if not in same section
          out.p.a(`${chapters.first.name}.html`).esc(section).aEnd.pEnd
          return
        }
      }

      // chapter lists
      out.ol
      chapters.each |c|
      {
        out.li("value='$c.num' style='counter-reset:chapter $c.num;'")
          .a(`${c.name}.html`).esc(c.name).aEnd

        // chapter sections
        if (c == cur)
        {
          out.ol
          c.headings.each |h|
          {
            out.li.a(`${c.name}.html#$h.anchorId`).esc(h.title).aEnd.liEnd
          }
          out.olEnd
        }
        out.liEnd
      }
      out.olEnd
    }
  }
}

