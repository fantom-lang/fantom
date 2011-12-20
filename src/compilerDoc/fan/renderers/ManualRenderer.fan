//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Sep 2011  Andy Frank  Creation
//

using web

**
** ManualRenderer renders DocPod chapter content.
**
** Index
** =====
**
**   <h1>{pod.name}</h1>
**   <p>{pod.summary}</p>
**
**   <div class='toc'>
**    <h2>{part.name}</h2>   // if available
**    <ol>
**     <li>
**      <a>{chapter.name}</a>
**      <p>{chapter.summary}</p>
**      <p><a>...</a>, <a>...</a></p>  // chapter headings
**     </li>
**    </ol>
**   </div>
**
** Chapter
** =======
**
**   <h1>
**    <span>{chapter.num}<span> {chapter.name}
**   </h1>
**   ... // chapter fandoc
**
** Chapter Nav
** ===========
**
**   <ul class='chapter-nav'>
**    <li class='prev'><a>{prev.name}</a></li>  // if available
**    <li class='next'><a>{next.name}</a></li>  // if available
**   </ul>
**
** Table of Contents
** =================
**
**   <h3><a>{pod.name}</a></h3>
**   <h4><a>{part.name}</a></h4>  // if available
**   <ol>
**    <li><a>{chapter.name}</a></li>
**    <li><a>{chapter.name}</a>
**     <ol>
**      <li><a>{heading.name}</a></li>
**     </ol>
**    </li>
**   </ol>
**
class ManualRenderer : DocRenderer
{
  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out, DocPod pod)
    : super(env, out)
  {
    this.pod = pod
  }

  ** Pod to renderer
  const DocPod pod

  ** Render the manual index of chapters.
  virtual Void writeIndex()
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

        // part header
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

  ** Write chapter content.
  virtual Void writeChapter(DocChapter chapter)
  {
    // heading
    out.h1
      .span.w("${chapter.num}.").spanEnd
      .w(" ").esc(chapter.name)
      .h1End

    // content
    writeFandoc(chapter, chapter.doc)
  }

  ** Write chapter prev/next navigation.
  virtual Void writeChapterNav(DocChapter cur)
  {
    out.ul("class='chapter-nav'")
    if (cur.prev != null)
      out.li("class='prev'")
        .a(`${cur.prev.name}.html`)
        .w("${cur.prev.num}. ").esc(cur.prev.name)
        .aEnd
        .liEnd
    if (cur.next != null)
      out.li("class='next'")
        .a(`${cur.next.name}.html`)
        .w("${cur.next.num}. ")
        .esc(cur.next.name).aEnd
        .liEnd
    out.ulEnd
  }

  ** Write out chapter table of contents for pod.
  virtual Void writeChapterToc(DocChapter cur)
  {
    // manual index
    out.h3.a(`index.html`).esc(pod.name).aEnd.h3End

    // map chapters into parts
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
    map.each |chapters, part|
    {
      // part header if defined
      if (!part.isEmpty)
      {
        if (chapters.contains(cur))
        {
          // part header
          out.h4.esc(part).h4End
        }
        else
        {
          // skip chapter list if not in same part
          out.h4.a(`${chapters.first.name}.html`).esc(part).aEnd.h4End
          return
        }
      }

      // chapter lists
      out.ol
      chapters.each |c|
      {
        // chapter name
        out.li("value='$c.num' style='counter-reset:chapter $c.num;'")
          .a(`${c.name}.html`).esc(c.name).aEnd

        // chapter headings
        if (c == cur)
        {
          out.ol
          c.headings.each |h|
          {
            out.li.a(`${c.name}.html#$h.anchorId`).esc(h.title).aEnd.liEnd
            if (h.children.size > 0)
            {
              out.ol
              h.children.each |sh|
              {
                out.li.a(`${c.name}.html#$sh.anchorId`).esc(sh.title).aEnd.liEnd
              }
              out.olEnd
            }
          }
          out.olEnd
        }
        out.liEnd
      }
      out.olEnd
    }
  }
}

