//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using web
using fandoc


**
** ChapterRenderer renders a manual chapter such
** as pod-doc or a page in docLang.
**
class ChapterRenderer : DocRenderer
{

  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out, DocChapter chapter)
    : super(env, out)
  {
    this.chapter = chapter

  }

  ** Chapter to renderer
  const DocChapter chapter

  ** Render the HTML for the DocType referened by `type` field.
  virtual Void writeChapter()
  {
    out.p.a(`../index.html`).w("Home").aEnd
      .w(" > ").a(`index.html`).w(chapter.pod).aEnd
      .w(" > ").a(`${chapter.name}.html`).w(chapter.name).aEnd
      .pEnd.hr

// TODO: don't love this design
     parser := FandocParser()
     parser.silent = true
     root := parser.parse(chapter.doc.loc.file, chapter.doc.text.in)
     headings := root.findHeadings

    writeStart(chapter.qname)
    writeHeadings(headings)
    doWriteFandoc(chapter, chapter.doc, parser, root)
    writeEnd
  }

  virtual Void writeHeadings(Heading[] headings)
  {
    headings.each |h|
    {
      out.span
      h.level.times |x| { out.w("&nbsp;&nbsp;&nbsp;&nbsp;") }
      if (h.anchorId == null) out.w(h.title)
      else out.a(`#${h.anchorId}`).w(h.title).aEnd
      out.spanEnd.br
    }
  }

}

