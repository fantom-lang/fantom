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

  ** Render the HTML for the DocType referened by `chapter` field.
  virtual Void writeChapter()
  {
    parser := FandocParser()
    parser.silent = true
    root := parser.parse(chapter.doc.loc.file, chapter.doc.text.in)
    doWriteFandoc(chapter, chapter.doc, parser, root)
  }
}

