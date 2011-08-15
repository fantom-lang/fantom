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
// Start/End
//////////////////////////////////////////////////////////////////////////

  ** Write starting HTML for page. Default implemenation calls
  ** `Theme.writeStart` for installed theme.
  virtual Void writeStart(Str titleStr)
  {
    env.theme.writeStart(this, titleStr)
  }

  ** Write ending HTML for page. Default implemenation calls
  ** `Theme.writeEnd` for installed theme.
  virtual Void writeEnd()
  {
    env.theme.writeEnd(this)
  }

  **
  ** Callback from `writeStart` to write any head includes
  **
  virtual Void writeHeadIncludes()
  {
  }

//////////////////////////////////////////////////////////////////////////
// Fanco
//////////////////////////////////////////////////////////////////////////

  ** Write the given fandoc string as HTML
  virtual Void writeFandoc(Str fandoc)
  {
    try
    {
// TODO
loc := "TODO"
      doc := FandocParser().parse(loc, fandoc.in)
      docOut := HtmlDocWriter(out)
      doc.children.each |child| { child.write(docOut) }
    }
    catch (Err e)
    {
// TODO
e.trace
    }
  }

}

