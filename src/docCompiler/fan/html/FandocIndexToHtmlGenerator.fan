//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** FandocIndexToHtmlGenerator generates an HTML file from an index.fog file.
**
class FandocIndexToHtmlGenerator : HtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Loc loc, OutStream out)
    : super(compiler, loc, out)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  override Str title()
  {
    return "Index"
  }

  override Void header()
  {
    out.print("<ul>\n")
    out.print("  <li><a href='../index.html'>$docHome</a></li>\n")
    out.print("  <li>&gt;</li>\n")
    out.print("  <li><a href='index.html'>$compiler.pod.name</a></li>\n")
    out.print("</ul>\n")
  }

  override Void content()
  {
    row := -1  // used to track tables

    out.print("<h1 class='title'>$compiler.pod.name</h1>\n")
    compiler.fandocIndex.each |Obj obj|
    {
      if (obj is Str)
      {
        // close table if open
        if (row != -1)
        {
          out.print("</table>\n")
          row = -1
        }

        // heading
        out.print("<h1>$obj</h1>\n")
        return
      }

      // open table if needed
      if (row == -1) out.print("<table>\n")
      row++

      cls  := row % 2 == 0 ? "even" : "odd"
      Obj link := ""
      Obj text := ""

      if (obj is Obj[])
      {
        link = (obj as Obj[])[0]
        text = (obj as Obj[])[1]
      }
      else
      {
        link = obj
      }

      out.print("<tr class='$cls'>\n")
      out.print("  <td><a href='${link}.html'>${toDisplay(link.toStr)}</a></td>\n")
      out.print("  <td>$text</td>\n")
      out.print("</tr>\n")
    }

    // make sure we close table
    if (row != -1) out.print("</table>\n")
  }

}

