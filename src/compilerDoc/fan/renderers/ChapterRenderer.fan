//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using web

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
    writeStart(chapter.qname)
    writeFandoc(chapter, chapter.doc)
    writeEnd
  }

}

