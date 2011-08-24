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

// TODO: don't love this design
    parser := FandocParser()
    parser.silent = true
    root := parser.parse(chapter.doc.loc.file, chapter.doc.text.in)
    this.headings = root.findHeadings

    // validate headings
    h1 := headings.findAll |h| { h.level == 1 }
    if (h1.size > 0) echo("ERR: H1 headings not allowed [$chapter]")
  }

  ** Chapter to renderer
  const DocChapter chapter

  ** Headings for chapter.
// TODO FIXIT: needs to move to DocChapter
  Heading[] headings

  ** Render the HTML for the DocType referened by `chapter` field.
  virtual Void writeChapter()
  {
    parser := FandocParser()
    parser.silent = true
    root := parser.parse(chapter.doc.loc.file, chapter.doc.text.in)
    doWriteFandoc(chapter, chapter.doc, parser, root)
  }
}

