//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 11  Brian Frank  Creation
//

**
** DocCrawler provides an interface to implement by search engine
** crawlers when crawling a specific document via `Doc.onCrawl`.
**
mixin DocCrawler
{
  ** Add plain, unformatted text to the index for current doc
  abstract Void addText(Str str)

  ** Add fandoc formatted text to the index for current doc
  abstract Void addFandoc(DocFandoc fandoc)

  ** Add a search keyword with a curated title, summary formatted
  ** as fandoc, and an optional fragment anchor within the document.
  ** This is used to index API keywords like types, slot name, qnames,
  ** etc.  The summary is used only for hit higlighting and should
  ** be added to the index itself separately.
  abstract Void addKeyword(Str keyword, Str title, DocFandoc summary, Str? anchor)
}