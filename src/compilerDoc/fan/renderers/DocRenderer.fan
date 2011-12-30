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
    this.env = env
    this.out = out
    this.doc = doc
    this.theme = env.theme
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** Environment with access to model, theme, linking, etc
  DocEnv env { private set }

  ** HTML output stream
  WebOutStream out { private set }

  ** Document to be renderered
  const Doc doc

  ** Theme to use for rendering chrome and navigation.
  ** This field is initialized from `DocEnv.theme`.
  const DocTheme theme

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
    loc := doc.loc
    parser := FandocParser()
    parser.silent = true
    root := parser.parse(loc.file, doc.text.in)

    // if no errors, then write as HTML
    if (parser.errs.isEmpty)
    {
      writer := HtmlDocWriter(out)
      writer.onLink = |Link elem|
      {
        // don't process absolute links
        orig := elem.uri
        if (orig.startsWith("http:/") ||
            orig.startsWith("https:/") ||
            orig.startsWith("ftp:/")) return

        try
        {
          // route to DocEnv.link
          link := env.link(this.doc, elem.uri, true)

          // get environment URI for the DocLink
          elem.uri = env.linkUri(link).encode
          elem.isCode = link.target.isCode

          // if link text was original URI, then update with DocLink.dis
          if (elem.children.first is DocText && elem.children.first.toStr == orig)
          {
            elem.children.clear
            elem.addChild(DocText(link.dis))
          }
        }
        catch (Err e)
        {
          if (elem.uri.startsWith("examples::"))
            elem.uri = "http://fantom.org/doc/" + elem.uri.replace("::", "/")
          else
            env.err(e.toStr, DocLoc(loc.file, loc.line+elem.line-1))
        }
      }
      root.children.each |child| { child.write(writer) }
    }

    // otherwise report errors and print as <pre>
    else
    {
      // report each error
      parser.errs.each |err|
      {
        env.err(err.msg, DocLoc(loc.file, loc.line + err.line - 1))
      }

      // print as <pre>
      out.pre.w(doc.text).preEnd
    }
  }
}

