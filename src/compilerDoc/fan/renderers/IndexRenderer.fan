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

    // type list
    out.table
    pod.types.each |type|
    {
      out.tr
        .td.a(`${type.name}.html`).w(type.name).aEnd.tdEnd
        .td.w(type.summary).tdEnd
        .trEnd
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
    out.ul("class='toc'")
    open := false
    pod.chapterIndex.each |item|
    {
      if (item is Str)
      {
        // close open list
        if (open) out.olEnd.liEnd
        open = true

        // section header
        out.li.esc(item)
        out.ol
      }
      else
      {
        // chapter
        name    := (Uri)item->get(0)
        summary := (Str)item->get(1)
        out.li
          .a(`${name}.html`).esc(name).aEnd
          .w(" &ndash; ").esc(summary)
          .liEnd
      }
    }
    out.olEnd.liEnd
    out.ulEnd
  }
}

