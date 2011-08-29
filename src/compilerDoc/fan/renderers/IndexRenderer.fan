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
  new make(DocEnv env, WebOutStream out)
    : super(env, out)
  {
  }

  ** Render the HTML pod's index of types
  virtual Void writeTypeIndex(DocPod pod)
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
          .td.w(type.summary).tdEnd
          .trEnd
      }
    }
    out.tableEnd
  }

  ** Render the HTML pod's index of chapters
  virtual Void writeChapterIndex(DocPod pod)
  {
    // name
    out.h1.w(pod.name).h1End
    out.p.esc(pod.summary).pEnd

    // contents
    out.div("class='toc'")
    open  := false
    index := 0
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
        index++

        // chapter
        c := item as DocChapter
        list := c.headings.join(", ") |h| {
          "<a href='${c.name}.html#$h.anchorId'>$h.title.toXml</a>"
        }
        out.li("value='$index'")
          .a(`${c.name}.html`).esc(c.name).aEnd
          .p.esc(c.summary).pEnd
          .p.w(list).pEnd
          .liEnd
      }
    }
    if (open) out.olEnd
    out.divEnd
  }
}

