//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using concurrent
using fandoc::FandocParser
using fandoc::Heading

**
** DocChapter models a fandoc "chapter" in a manual like docLang
**
const class DocChapter : Doc
{
  ** Constructor
  internal new make(DocPodLoader loader, File f)
  {
    this.pod   = loader.pod
    this.name  = f.name == "pod.fandoc" ? "pod-doc" : f.basename
    this.loc   = DocLoc("${pod}::${f.name}", 1)
    this.doc   = DocFandoc(this.loc, f.in.readAllStr)
    this.qname = "$pod.name::$name"

    // parse fandoc and build the headings tree
    headingTop := DocHeading[,]
    headingMap := Str:DocHeading[:]
    meta := Str:Str[:]
    try
    {
      // parse fandoc silently - don't worry about errors,
      // we'll catch and report them at render time
      parser := FandocParser()
      parser.silent = true
      fandocDoc := parser.parse(f.name, doc.text.in)
      meta = fandocDoc.meta
      fandocHeadings := fandocDoc.findHeadings

      // map headings into tree structure
      buildHeadingsTree(loader, fandocHeadings, headingTop, headingMap)
    }
    catch (Err e)
    {
      loader.err("Cannot parse fandoc chapter", loc, e)
    }
    this.headings = headingTop
    this.headingMap = headingMap
    this.meta = meta
  }

  private Void buildHeadingsTree(DocPodLoader loader, Heading[] fandoc, DocHeading[] top, Str:DocHeading map)
  {
    // if no headings just bail
    if (fandoc.isEmpty) return

    // first map Fandoc headings to DocHeadings and map by anchor id
    headings := DocHeading[,]
    children := DocHeading:DocHeading[][:]
    fandoc.each |d|
    {
      id := d.anchorId
      h := DocHeading { it.level = d.level; it.title = d.title; it.anchorId = id}
      if (id == null) loader.err("Heading missing anchor id: $h.title", loc)
      else if (map[id] != null) loader.err("Heading duplicate anchor id: $id", loc)
      else map[id] = h
      headings.add(h)
      children[h] = DocHeading[,]
    }

    // now map into a tree structure
    stack := DocHeading[,]
    headings.each |h|
    {
      while (stack.peek != null && stack.peek.level >= h.level)
        stack.pop

      // top level heading
      if (stack.isEmpty)
      {
        if (h.level != 2 && pod.name != "fandoc")
          loader.err("Expected top-level heading to be level 2: $h.title", loc)
        top.add(h)
      }

      // child level heading
      else
      {
        if (stack.peek.level +1 != h.level)
          loader.err("Expected heading to be level ${stack.peek.level+1}: $h.title", loc)
        children[stack.peek].add(h)
      }

      stack.add(h)
    }

    // map children map to immutable list fields
    children.each |kids, h| { h.childrenRef.val = kids.toImmutable }
  }

  ** Pod which defines this chapter such as "docLang"
  const DocPod pod

  ** Simple name of the chapter such as "Overview" or "pod-doc"
  const Str name

  ** Document name under space is same as `name`
  override Str docName() { name }

  ** The space for this doc is `pod`
  override DocSpace space() { pod }

  ** Title is 'meta.title', or qualified name if not specified.
  override Str title() { meta["title"] ?: qname }

  ** Default renderer is `DocChapterRenderer`
  override Type renderer() { DocChapterRenderer# }

  ** Return if this chapter is the special "pod-doc" file
  Bool isPodDoc() { name == "pod-doc" }

  ** Qualified name as "pod::name"
  const Str qname

  ** Location for chapter file
  const DocLoc loc

  ** Fandoc heating metadata
  const Str:Str meta

  ** Chapter contents as Fandoc string
  const DocFandoc doc

  ** Top-level chapter headings
  const DocHeading[] headings

  ** Chapter number (one-based)
  Int num() { numRef.val }
  internal const AtomicInt numRef := AtomicInt()

  ** Summary for TOC
  Str summary() { summaryRef.val }
  internal const AtomicRef summaryRef := AtomicRef("")

  ** Previous chapter in TOC order or null if first
  DocChapter? prev() { prevRef.val }
  internal const AtomicRef prevRef := AtomicRef(null)

  ** Next chapter in TOC order or null if last
  DocChapter? next() { nextRef.val }
  internal const AtomicRef nextRef := AtomicRef(null)

  ** Get a chapter heading by its anchor id or raise NameErr/return null.
  DocHeading? heading(Str id, Bool checked := true)
  {
    h := headingMap[id]
    if (h != null) return h
    if (checked) throw NameErr("Unknown header anchor id ${qname}#${id}")
    return null
  }

  ** Return qname
  override Str toStr() { qname }

  private const Str:DocHeading headingMap

  ** Index the chapter name and body
  override Void onCrawl(DocCrawler crawler)
  {
    summary := DocFandoc(this.loc, this.summary)
    crawler.addKeyword(name, title, summary, null)
    crawler.addKeyword(qname, title, summary, null)
    crawler.addFandoc(doc)
  }
}

**
** DocHeader models a heading in a table of contents for pod/chapter.
**
const class DocHeading
{
  ** Constructor
  internal new make(|This| f) { f(this) }

  ** Heading level, chapter top-level sections start at level 2
  const Int level

  ** Display title for the heading
  const Str title

  ** Anchor id for heading or null if not available
  const Str? anchorId

  ** Children headings
  DocHeading[] children() { childrenRef.val }
  internal const AtomicRef childrenRef := AtomicRef()
}