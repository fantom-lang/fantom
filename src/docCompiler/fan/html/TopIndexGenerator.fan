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

  new make(DocCompiler compiler, Loc loc, OutStream out)
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
    // get all pods to document
    pods := Pod.list.rw
    pods = pods.exclude |p| { p.meta["pod.docApi"] == "false" }

    // get sensible order
    pods = pods.sort |a,b| { a.name.compareIgnoreCase(b.name) }
    pods.swap(0, pods.index(Pod.find("docIntro")))
    pods.swap(1, pods.index(Pod.find("docLang")))

    // Manuals
    manuals := TopIndexItem[,]
    pods.each |p| { if (!isAPI(p)) manuals.add(TopIndexItem(p)) }
    listPods("Manuals", manuals)

    // Examples
    examples := TopIndexItem[,]
    examples.add(TopIndexItem.makeExplicit("examples", "Example code illustrated via series of scripts"))
    listPods("Examples", examples)

    // APIs
    apis := TopIndexItem[,]
    pods.each |p| { if (isAPI(p)) apis.add(TopIndexItem(p)) }
    apis.sort |a,b| { a.name.compareIgnoreCase(b.name) }
    listPods("APIs", apis)
  }

  internal Void listPods(Str title, TopIndexItem[] items)
  {
    out.print("<h1>$title</h1>\n")
    out.print("<table>\n")
    items.each |item, i|
    {
      cls := i % 2 == 0 ? "even" : "odd"
      out.print("<tr class='$cls'>\n")
      out.print("  <td><a href='$item.name/index.html'>$item.name</a></td>\n")
      out.print("  <td>$item.doc</td>\n")
      out.print("</tr>\n")
    }
    out.print("</table>\n")
  }

  internal Bool isAPI(Pod pod)
  {
    if (!pod.name.startsWith("doc")) return true
    if (pod.name == "docCompiler") return true
    return false
  }

}

internal class TopIndexItem
{
  new make(Pod p)
  {
    name = p.name
    doc = HtmlDocUtil.firstSentence(p.meta["pod.summary"] ?: "")
  }

  new makeExplicit(Str n, Str d)
  {
    name = n
    doc = d
  }

  Str name
  Str doc
}