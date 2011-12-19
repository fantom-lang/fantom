//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using concurrent
using fandoc

**
** DocChapter models a fandoc "chapter" in a manual like docLang
**
const class DocChapter : DocPage
{
  ** Constructor
  internal new make(DocEnv env, Str pod, File f)
  {
    this.pod  = pod
    this.name = f.name == "pod.fandoc" ? "pod-doc" : f.basename
    this.loc  = DocLoc("${pod}::${f.name}", 1)
    this.doc  = DocFandoc(this.loc, f.in.readAllStr)

    // parse fandoc and build the headings tree
    headingTop := DocHeading[,]
    headingMap := Str:DocHeading[:]
    try
    {
      // parse fandoc silently - don't worry about errors,
      // we'll catch and report them at render time
      parser := FandocParser()
      parser.silent = true
      fandocHeadings := parser.parse(f.name, doc.text.in).findHeadings

      // map headings into tree structure
      buildHeadingsTree(env, fandocHeadings, headingTop, headingMap)
    }
    catch (Err e)
    {
      env.err("Cannot parse fandoc chapter", loc, e)
    }
    this.headings = headingTop
    this.headingMap = headingMap
  }

  private Void buildHeadingsTree(DocEnv env, Heading[] fandoc, DocHeading[] top, Str:DocHeading map)
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
      if (id == null) env.err("Heading missing anchor id: $h.title", loc)
      else if (map[id] != null) env.err("Heading duplicate anchor id: $id", loc)
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
        if (h.level != 2 && this.pod != "fandoc")
          env.err("Expected top-level heading to be level 2: $h.title", loc)
        top.add(h)
      }

      // child level heading
      else
      {
        if (stack.peek.level +1 != h.level)
          env.err("Expected heading to be level ${stack.peek.level+1}: $h.title", loc)
        children[stack.peek].add(h)
      }

      stack.add(h)
    }

    // map children map to immutable list fields
    children.each |kids, h| { h.childrenRef.val = kids.toImmutable }
  }

  ** Pod name which defines this chapter such as "docLang"
  const Str pod

  ** Simple name of the chapter such as "Overview" or "pod-doc"
  const Str name

  ** Title is the qualified name of the document
  override Str title() { "$pod::$name" }

  ** Return if this chapter is the special "pod-doc" file
  Bool isPodDoc() { name == "pod-doc" }

  ** Qualified name as "pod::name"
  Str qname() { "$pod::$name" }

  ** Location for chapter file
  const DocLoc loc

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