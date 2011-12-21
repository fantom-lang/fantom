//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Sep 2011  Andy Frank  Creation
//

using web

**
** Renders DocChapter documents
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
class DocChapterRenderer : DocRenderer
{
  new make(DocEnv env, WebOutStream out, DocChapter doc)
    : super(env, out, doc)
  {
    this.chapter = doc
  }

  ** Chapter document to renderer
  const DocChapter chapter

  override Void writeContent()
  {
    // content
    out.div("class='mainSidebar'")
    out.div("class='main chapter'")
    writeNav
    writeBody
    writeNav
    out.divEnd

    // toc
    out.div("class='sidebar'")
    writeToc
    out.divEnd
    out.divEnd
  }

  ** Write chapter body.
  virtual Void writeBody()
  {
    // heading
    out.h1
      .span.w("${chapter.num}.").spanEnd
      .w(" ").esc(chapter.name)
      .h1End

    // content
    writeFandoc(chapter.doc)
  }

  ** Write chapter prev/next navigation.
  virtual Void writeNav()
  {
    cur := chapter
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
  virtual Void writeToc()
  {
    // manual index
    out.h3.a(`index.html`).esc(chapter.pod.name).aEnd.h3End

    // map chapters into parts
    cur := this.chapter
    map  := Str:DocChapter[][:] { ordered=true }
    last := ""
    chapter.pod.index.toc.each |item|
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