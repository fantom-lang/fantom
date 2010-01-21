//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 May 07  Andy Frank  Creation
//

using compiler
using fandoc

**
** SourceToHtmlGenerator generates an syntax color coded HTML
** file for a Type's source code.
**
class SourceToHtmlGenerator : ApiToHtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Loc loc, OutStream out, Type t, File srcFile)
    : super(compiler, loc, out, t)
  {
    this.srcFile     = srcFile
    this.podHeading  = t.pod.name
    this.typeHeading = t.name
  }

//////////////////////////////////////////////////////////////////////////
// ApiToHtmlGenerator
//////////////////////////////////////////////////////////////////////////

  **
  ** Generate the main content.
  **
  override Void content()
  {
    // print type header if not script
    if (!isScript)
    {
      out.print("<div class='type'>\n")
      typeOverview
      out.print("</div>\n")
    }

    // build slot:lineNum map
    slots := Str:Int[:]
    t.slots.each |Slot s|
    {
      if (s.parent == t) slots[s.name] = s->lineNumber
    }

    // generate
    FanToHtml(srcFile.in, out, slots).parse
  }

  **
  ** Generate the sidebar.
  **
  override Void sidebar()
  {
    // only display More Info if our source isn't a script
    if (!isScript)
    {
      out.print("<h2>More Info</h2>\n")
      out.print("<ul class='clean'>\n")
      out.print("  <li><a href='${t.name}.html'>View Fandoc</a></li>\n")
      out.print("</ul>\n")
    }

    slotsOverview(false)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File srcFile
  override Str podHeading
  override Str typeHeading
  Bool isScript
}