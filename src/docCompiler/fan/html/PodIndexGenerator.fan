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
** PodIndexGenerator generates the index file for a pod.
**
class PodIndexGenerator : HtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Loc loc, OutStream out)
    : super(compiler, loc, out)
  {
    this.pod = compiler.pod
    this.types = pod.types.rw.findAll |t| { showType(t) }
    this.types = types.sort |a,b| { a.name.compareIgnoreCase(b.name) }
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  ** Doc title.
  override Str title() { pod.name }

  ** Doc header.
  override Void header()
  {
    out.printLine(
      "<ul>
        <li><a href='../index.html'>$docHome</a></li>
        <li>&gt;</li>
        <li><a href='index.html'>$pod.name</a></li>
       </ul>")
  }

  ** Doc content.
  override Void content()
  {
    out.printLine("<div class='type'>")
    writeOverview
    writeDoc
    writeTypes
    out.printLine("</div>")
  }

  ** Write pod overview.
  Void writeOverview()
  {
    out.printLine(
      "<div class='overview'>
        <h2>pod</h2>
        <h1>$pod.name</h1>
       </div>")
  }

  ** Write pod fandoc if applicable.
  Void writeDoc()
  {
    meta := pod.meta["pod.summary"]
    if (meta == null) return
    out.printLine("<div class='detail'>$meta</div>")

    /*
    // check for fandoc
    file := pod.file(`/doc/pod.fandoc`, false)
    if (file == null) return

    // compile fandoc
    doc := FandocParser().parse(pod.name, file.in)
    if (doc.children.isEmpty) return

    // only display first paragraph
    out.print("<div class='detail'>")
    p := doc.children.find |n| { n is Para }
    p?.write(this)
    out.printLine("</div>")
    */
  }

  ** Write type listing for this pod.
  Void writeTypes()
  {
    // sort by type
    mixins  := Type[,]
    classes := Type[,]
    enums   := Type[,]
    facets  := Type[,]
    errs    := Type[,]
    types.each |t|
    {
      if (t.isMixin) { mixins.add(t); return }
      if (t.isEnum)  { enums.add(t); return }
      if (t.isFacet) { facets.add(t); return }
      if (t.fits(Err#)) { errs.add(t); return }
      classes.add(t)
    }

    // list types
    typeTable("Mixins", mixins)
    typeTable("Classes", classes)
    typeTable("Enums", enums)
    typeTable("Facets", facets)
    typeTable("Errs", errs)
  }

  ** Write out type-group table.
  Void typeTable(Str header, Type[] list)
  {
    if (list.isEmpty) return
    out.printLine("<h2>$header</h2>")
    out.printLine("<table>")
    list.each |t,i|
    {
      // apply zebra-stripping
      cls := i % 2 == 0 ? "even" : "odd"
      uri := compiler.uriMapper.map(t.qname, loc)
      out.printLine(
        "<tr class='$cls'>
          <td><a href='$uri'>$t.name</a></td>
          <td>")

      // display type name along with first sentence of fandoc
      doc := t.doc
      if (doc != null)
      {
        try
        {
          doc = HtmlDocUtil.firstSentence(doc)
          fandoc := FandocParser.make.parse("API for $t", doc.in)
          para := fandoc.children.first as Para
          para.children.each |DocNode child| { child.write(this) }
        }
        catch (Err e)
        {
          compiler.log.err("Failed to generate fandoc for $t.qname")
        }
      }
      out.printLine("</td>")
      out.printLine("</tr>")
    }
    out.printLine("</table>")
  }

  ** Doc sidebar.
  override Void sidebar()
  {
    // pod-level metadata
    out.printLine(
      "<h2>Pod</h2>
        <ul class='clean'>
         <li><a href='pod-doc.html'>PodDoc</a>
        </ul>")

    // all-type listing
    out.printLine("<h2>All Types</h2>")
    out.printLine("<ul class='clean'>")
    types.each |t|
    {
      uri := compiler.uriMapper.map(t.qname, loc)
      out.printLine("<li><a href='$uri'>$t.name</a></li>")
    }
    out.printLine("</ul>")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Pod pod
  Type[] types

}