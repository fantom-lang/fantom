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
**    <span>{chapter.num}<span> {chapter.title}
**   </h1>
**   ... // chapter fandoc
**
** Chapter Nav
** ===========
**
**   <ul class='chapter-nav'>
**    <li class='prev'><a>{prev.title}</a></li>  // if available
**    <li class='next'><a>{next.title}</a></li>  // if available
**   </ul>
**
** Table of Contents
** =================
**
**   <h3><a>{pod.name}</a></h3>
**   <h4><a>{part.name}</a></h4>  // if available
**   <ol>
**    <li><a>{chapter.title}</a></li>
**    <li><a>{chapter.title}</a>
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
    out.h1.span.w("${chapter.num}.").spanEnd.w(" ").esc(chapter.title).h1End
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
    writeFandoc(chapter.doc)
  }

  ** Write chapter prev/next navigation.
  virtual Void writeNav()
  {
    cur := chapter
    out.ul("class='chapter-nav'")
    if (cur.prev != null)
    {
      out.li("class='prev'")
      writeLinkTo(cur.prev, "${cur.prev.num}. $cur.prev.title")
      out.liEnd
    }
    if (cur.next != null)
    {
      out.li("class='next'")
      writeLinkTo(cur.next, "${cur.next.num}. $cur.next.title")
      out.liEnd
    }
    out.ulEnd
  }

  ** Write out chapter table of contents for pod.
  virtual Void writeToc()
  {
    // manual index
    out.h3
    writeLinkTo(chapter.pod.index, chapter.pod.name)
    out.h3End

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
          out.h4
          writeLinkTo(chapters.first, part)
          out.h4End
          return
        }
      }

      // chapter lists
      out.ol
      chapters.each |c|
      {
        // chapter name
        out.li("value='$c.num' style='counter-reset:chapter $c.num;'")
        writeLinkTo(c)

        // chapter headings
        if (c == cur)
        {
          out.ol
          c.headings.each |h|
          {
            out.li
            writeLinkTo(c, h.title, h.anchorId)
            out.liEnd
            if (h.children.size > 0)
            {
              out.ol
              h.children.each |sh|
              {
                out.li
                writeLinkTo(c, sh.title, sh.anchorId)
                out.liEnd
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