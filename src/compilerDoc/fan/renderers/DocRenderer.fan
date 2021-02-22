//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using fandoc
using fandoc::Doc as FandocDoc
using web

**
** DocRenderer is base class for rendering a Doc.
** See `writeDoc` for rendering pipeline.
**
abstract class DocRenderer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** All subclasses must implement ctor with env, out, doc params.
  new make(DocEnv env, WebOutStream out, Doc doc)
  {
    this.envRef = env
    this.outRef = out
    this.docRef = doc
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** Environment with access to model, theme, linking, etc
  virtual DocEnv env() { envRef }
  private DocEnv envRef

  ** HTML output stream
  virtual WebOutStream out() { outRef }
  private WebOutStream outRef

  ** Document to be renderered
  virtual Doc doc() { docRef }
  private Doc docRef

  ** Theme to use for rendering chrome and navigation.
  ** This field is initialized from `DocEnv.theme`.
  virtual DocTheme theme() { env.theme }

//////////////////////////////////////////////////////////////////////////
// Hooks
//////////////////////////////////////////////////////////////////////////

  **
  ** Render the `doc`.  This method delegates to:
  **  1. `DocTheme.writeStart`
  **  2. `DocTheme.writeBreadcrumb`
  **  3. `writeContent`
  **  3. `DocTheme.writeEnd`
  **
  virtual Void writeDoc()
  {
    theme.writeStart(this)
    theme.writeBreadcrumb(this)
    writeContent
    theme.writeEnd(this)
  }

  **
  ** Subclass hook to render document specific content.
  ** See `writeDoc` for rendering pipeline.
  **
  abstract Void writeContent()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Write an '<a>' element for the given link from this renderer
  ** document to another document.  See `DocEnv.linkUri`.
  **
  virtual Void writeLink(DocLink link)
  {
    out.a(env.linkUri(link)).esc(link.dis).aEnd
  }

  **
  ** Convenience for 'writeLink(linkTo(target, dis, frag))'
  **
  virtual Void writeLinkTo(Doc target, Str? dis := null, Str? frag := null)
  {
    if (dis == null) dis = target is DocChapter ? target.title : target.docName
    writeLink(linkTo(target, dis, frag))
  }

  **
  ** Create a DocLink from this renderer doc to the target document.
  **
  DocLink linkTo(Doc target, Str? dis := null, Str? frag := null)
  {
    if (dis == null) dis = target is DocChapter ? target.title : target.docName
    return DocLink(this.doc, target, dis, frag)
  }

  **
  ** Write the given fandoc string as HTML.  This method
  ** delegates to `DocEnv.link` and `DocEnv.linkUri` to
  ** resolve links from the current document.
  **
  virtual Void writeFandoc(DocFandoc doc)
  {
    // parse fandoc
    docLoc := doc.loc
    parser := FandocParser()
    parser.silent = true
    root := parser.parse(docLoc.file, doc.text.in)

    // if no errors, then write as HTML
    if (parser.errs.isEmpty)
    {
      writer := HtmlDocWriter(out)
      writer.onLink  = |Link elem| { onFandocLink(elem, toFandocElemLoc(docLoc, elem.line)) }
      writer.onImage = |Image elem| { onFandocImage(elem, toFandocElemLoc(docLoc, elem.line)) }
      root.children.each |child| { child.write(writer) }
    }

    // otherwise report errors and print as <pre>
    else
    {
      // report each error
      parser.errs.each |err|
      {
        env.err(err.msg, toFandocElemLoc(docLoc, err.line))
      }

      // print as <pre>
      out.pre.w(doc.text).preEnd
    }
  }

  ** Map document location and element to the element location
  private DocLoc toFandocElemLoc(DocLoc docLoc, Int line)
  {
    DocLoc(docLoc.file, docLoc.line + line - 1)
  }

  ** Fandoc handling for link nodes
  @NoDoc
  virtual Void onFandocLink(Link elem, DocLoc loc)
  {
    // don't process absolute links
    orig := elem.uri
    if (orig.startsWith("http:/") ||
        orig.startsWith("https:/") ||
        orig.startsWith("ftp:/")) return

    try
    {
      // route to DocEnv.link
      link := resolveFandocLink(elem, true)

      // get environment URI for the DocLink
      elem.uri = env.linkUri(link).encode
      elem.isCode = link.target.isCode

      // extra checking
      env.linkCheck(link, loc)

      // if link text was original URI, then update with DocLink.dis
      if (elem.children.first is DocText && elem.children.first.toStr == orig)
      {
        elem.removeAll.add(DocText(link.dis))
      }
    }
    catch (Err e)
    {
      if (elem.uri.startsWith("examples::"))
        elem.uri = "https://fantom.org/doc/" + elem.uri.replace("::", "/")
      else
        onFandocErr(e, loc)
    }
  }

  ** Fandoc handling for inage nodes
  @NoDoc
  virtual Void onFandocImage(Image elem, DocLoc loc)
  {
  }

  **
  ** Hook used to map a fandoc link to a doc link
  **
  virtual DocLink? resolveFandocLink(Link elem, Bool checked := true)
  {
    env.link(this.doc, elem.uri, true)
  }

  ** Handle a fandoc linking error
  @NoDoc
  virtual Void onFandocErr(Err e, DocLoc loc)
  {
    env.err(e.toStr, loc)
  }
}