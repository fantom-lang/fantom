//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using fandoc
using web

**
** DocRenderer is base class for renders for various documentation
** pages for indices, types, etc.
**
class DocRenderer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** All subclasses must implement ctor with env, out params.
  new make(DocEnv env, WebOutStream out)
  {
    this.env = env
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** Environment with access to model, theme, linking, etc
  DocEnv env { private set }

  ** HTML output stream
  WebOutStream out { private set }

//////////////////////////////////////////////////////////////////////////
// Fanco
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the given fandoc string as HTML.  The base must
  ** one of the types supported by `DocLinker.link` (such as
  ** DocPod or DocType).
  **
  virtual Void writeFandoc(Obj base, DocFandoc doc)
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
        try
        {
          // route to DocLinker
          orig := elem.uri
          link := env.makeLinker(base, elem.uri, DocLoc(loc.file, loc.line+elem.line-1)).resolve

          // update link element
          elem.uri = link.uri.encode
          elem.isCode = link.isCode

          // if link text was original URI, then update with DocLin.dis
          if (elem.children.first is DocText && elem.children.first.toStr == orig)
          {
            elem.children.clear
            elem.addChild(DocText(link.dis))
          }
        }
        catch (DocErr e) env.errReport(e)
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

