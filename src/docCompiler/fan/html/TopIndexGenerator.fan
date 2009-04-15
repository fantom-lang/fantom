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
** TopIndexGenerator generates the top level index file.
**
class TopIndexGenerator : HtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Location loc, OutStream out)
    : super(compiler, loc, out)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  override Str title()
  {
    return docHome
  }

  override Str pathToRoot()
  {
    return ""
  }

  override Void header()
  {
    out.print("<ul>\n")
    out.print("  <li><a href='index.html'>$docHome</a></li>\n")
    out.print("</ul>\n")
  }

  override Void content()
  {
    listPods("Manuals", false)
    listPods("APIs", true)
  }

  Void listPods(Str title, Bool api)
  {
    out.print("<h1>$title</h1>\n")
    out.print("<table>\n")

    pods := Pod.list.rw
    pods.swap(0, pods.index(Pod.find("docIntro")))
    pods.swap(1, pods.index(Pod.find("docLang")))

    pods = pods.exclude |p| { p.facet("doc") == false }
    pods = pods.findAll |p| { api == isAPI(p) }
    pods = pods.sort |a,b| { a.name.compareIgnoreCase(b.name) }

    pods.each |Pod p, Int i|
    {
      cls := i % 2 == 0 ? "even" : "odd"
      doc := p.facets["description"]
      out.print("<tr class='$cls'>\n")
      out.print("  <td><a href='$p.name/index.html'>$p.name</a></td>\n")
      out.print("  <td>$doc</td>\n")
      out.print("</tr>\n")
    }
    out.print("</table>\n")
  }

  Bool isAPI(Pod pod)
  {
    if (!pod.name.startsWith("doc")) return true
    if (pod.name == "docCompiler") return true
    return false
  }

}