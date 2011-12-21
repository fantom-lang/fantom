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
  const DocTheme theme := DocTheme()

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
    doc := space(spaceName, false)?.doc(docName)
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

** TODO
  DocErr err(Str msg, DocLoc loc, Err? cause := null)
  {
    errReport(DocErr(msg, loc, cause))
  }

** TODO
  virtual DocErr errReport(DocErr err)
  {
    echo("$err.loc: $err.msg")
    if (err.cause != null) err.cause.trace
    return err
  }

** TODO
  ** `DocLinker` to use for resolving fandoc hyperlinks.  See `makeLinker`.
  const Type linker := DocLinker#

** TODO
  ** Constructor a linker to use for given base object,
  ** link str and location.
  DocLinker makeLinker(Obj base, Str link, DocLoc loc)
  {
    func := Field.makeSetFunc([
      DocLinker#env:  this,
      DocLinker#base: base,
      DocLinker#link: link,
      DocLinker#loc:  loc])
    return linker.make([func])
  }
}