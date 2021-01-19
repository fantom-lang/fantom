//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

using web

**
** DocEnv is the centralized glue class for managing documentation
** modeling and rendering:
**   - hooks for lookup and loading of spaces/pods
**   - hooks for theming HTML chrome and navigation
**   - hooks for renderering HTML pages
**   - hooks for hyperlink resolution
**
abstract const class DocEnv
{
  **
  ** Theme is responsible for the common chrome, styling, and
  ** navigation during rendering
  **
  virtual DocTheme theme() { DocTheme() }

  **
  ** Get the document which represents top level index.
  **
  virtual DocTopIndex topIndex() { DocTopIndex() }

  **
  ** Lookup a space by its space name.  If not found then return
  ** null or raise UnknownDocErr.  This method is called frequently
  ** during document rendering and linking so caching is expected.
  **
  abstract DocSpace? space(Str name, Bool checked := true)

  **
  ** Lookup a document by is spaceName and docName within that
  ** space.  If not found then return null or raise UnknownDocErr.
  ** Default implementation delegates to `space` and `DocSpace.doc`.
  **
  virtual Doc? doc(Str spaceName, Str docName, Bool checked := true)
  {
    doc := space(spaceName, false)?.doc(docName, false)
    if (doc != null) return doc
    if (checked) throw UnknownDocErr("$spaceName::$docName")
    return null
  }

  **
  ** Render the given document to the specified output stream.
  ** Default implementation uses `Doc.renderer`.
  **
  virtual Void render(WebOutStream out, Doc doc)
  {
    DocRenderer r := doc.renderer.make([this, out, doc])
    r.writeDoc
  }

  **
  ** Return URI used to link the from doc to the target doc.
  ** Also see `linkUriExt`.
  **
  virtual Uri linkUri(DocLink link)
  {
    if (link.absUri != null) return link.absUri
    s := StrBuf()
    if (link.from.isTopIndex)
    {
      if (!link.target.isTopIndex)
        s.add(link.target.space.spaceName).add("/")
    }
    else if (link.target.isTopIndex)
    {
      s.add("../")
    }
    else if (link.from.space !== link.target.space)
    {
      s.add("../").add(link.target.space.spaceName).add("/")
    }
    docName := link.target.docName
    if (docName == "pod-doc") docName = "index"
    s.add(docName)
    ext := linkUriExt
    if (ext != null) s.add(ext)
    if (link.frag != null) s.add("#").add(link.frag)
    return s.toStr.toUri
  }

  **
  ** Return the file extension (including the dot) to
  ** suffix all link URIs.  Default returns ".html"
  **
  virtual Str? linkUriExt() { ".html"}

  **
  ** Resolve the link relative to the given from document.
  ** See `DocLink` for the built-in formats.
  **
  virtual DocLink? link(Doc from, Str link, Bool checked := true)
  {
    // if absolute spaceName::docName
    colons := link.index("::")
    space := from.space as DocSpace
    docName := link
    if (colons != null)
    {
      spaceName := link[0..<colons]
      docName   = link[colons+2..-1]
      space     = this.space(spaceName, checked)
      if (space == null) return null
    }

    // check if we have a Type.slot
    dot := docName.index(".")
    if (dot != null)
    {
      typeName := docName[0..<dot]
      slotName := docName[dot+1..-1]
      type := space.doc(typeName, false) as DocType
      if (type != null)
      {
        slot := type.slot(slotName)
        if (slot != null) return DocLink(from, type, "${typeName}.${slotName}", slotName)
      }
    }

    // check for slot in Type
    if (from is DocType)
    {
      slot := ((DocType)from).slot(docName, false)
      if (slot != null) return DocLink(from, from, docName, docName)
    }

    // check if we have Chatper#frag
    pound := docName.index("#")
    if (pound != null)
    {
      chapterName := docName[0..<pound]
      headingName := docName[pound+1..-1]
      doc := (chapterName.isEmpty ? from : space.doc(chapterName, false))
      if (doc != null)
      {
        heading := doc.heading(headingName, false)
        if (heading != null) return DocLink(from, doc, doc.title, headingName)
      }
    }

    // check for document
    doc := space.doc(docName, false)
    if (doc != null)
    {
      if (doc is DocType) return DocLink(from, doc, doc.docName)
      return DocLink(from, doc, doc.title)
    }

    // no joy
    if (checked) throw Err("Broken link: $link")
    return null
  }

  **
  ** Hook to perform extra DocLink checking such as links to NoDocs
  **
  virtual Void linkCheck(DocLink link, DocLoc loc)
  {
    type := link.target as DocType
    if (type != null)
    {
      if (type.isNoDoc) errReport(DocErr("Link to NoDoc type $type.qname", loc))
      else if (link.frag != null)
      {
        slot := type.slot(link.frag, false)
        if (slot != null && slot.isNoDoc) errReport(DocErr("Link to NoDoc slot $slot.qname", loc))
      }
    }
  }

  DocErr err(Str msg, DocLoc loc, Err? cause := null)
  {
    errReport(DocErr(msg, loc, cause))
  }

  virtual DocErr errReport(DocErr err)
  {
    echo("$err.loc: $err.msg")
    if (err.cause != null) err.cause.trace
    return err
  }
}