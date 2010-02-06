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
** FandocToHtmlGenerator generates an HTML file for a standalone fandoc file
**
class FandocToHtmlGenerator : HtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Loc loc, File file, Doc? doc)
    : super(compiler, loc, file.out)
  {
    this.file = file
    this.doc  = doc
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  override Str title()
  {
    title := doc.meta["title"]
    if (title != null) return toDisplay(title)
    err("Missing title", loc)
    return super.title
  }

  override Void header()
  {
    out.print("<ul>\n")
    out.print("  <li><a href='../index.html'>$docHome</a></li>\n")
    out.print("  <li>&gt;</li>\n")
    out.print("  <li><a href='index.html'>$compiler.pod.name</a></li>\n")
    out.print("  <li>&gt;</li>\n")
    out.print("  <li><a href='${file.basename}.html'>$title</a></li>\n")
    out.print("</ul>\n")
  }

  override Void content()
  {
    findPrevNext
    prevNext
    out.print("<h1 class='title'>$title</h1>\n")
    doc.children.each |DocNode node| { node.write(this) }
    prevNext
  }

  override Void sidebar()
  {
    // make a quick run thru to make sure we even
    // have any headers for the content sidebar
    temp := doc?.children?.find |DocNode node->Bool| { return node is Heading }
    if (temp == null) return

    // we found some so print them
    out.print("<h2>Contents</h2>\n")
    out.print("<ul>\n")
    ListNode.fromDocNodes(doc.children).kids.each |ListNode node| { writeListNode(node) }
    out.print("</ul>\n")
  }

  private Void writeListNode(ListNode node)
  {
    out.print("<li>")
    id := node.heading.anchorId
    if (id != null) out.print("<a href='#$id'>")
    node.heading.children.each |DocNode n| { n.write(this) }
    if (id != null) out.print("</a>")
    if (node.kids.size > 0)
    {
      out.print("<ul>\n")
      node.kids.each |ListNode child| { writeListNode(child) }
      out.print("</ul>\n")
    }
    out.print("</li>")
  }

  Void prevNext()
  {
    if (prev == null && next == null) return
    out.print("<div class='prevNext'>\n")
    if (prev != null)
    {
      out.print("<div class='prev'>")
      out.print("<a href='${prev}.html'>")
      out.print("<img src='${pathToRoot}go-previous.png' alt='prev' />")
      out.print("</a>")
      out.print(" <a href='${prev}.html'>${toDisplay(prev.name)}</a>")
      out.print("</div>\n")
    }
    if (next != null)
    {
      out.print("<div class='next'>")
      out.print("<a href='${next}.html'>${toDisplay(next.name)}</a>")
      out.print(" <a href='${next}.html'>")
      out.print("<img src='${pathToRoot}go-next.png' alt='next' />")
      out.print("</a>")
      out.print("</div>\n")
    }
    out.print("</div>\n")
  }

  Void findPrevNext()
  {
    if (compiler.fandocIndex == null) return

    // give something easier to work with
    index := [,]
    for (i:=0; i<compiler.fandocIndex.size; i++)
    {
      v := compiler.fandocIndex[i]
      if (v is Uri) index.push(v)
      else if (v is Obj[]) index.push((v as Obj[])[0] as Uri)
    }

    // try to find prev/next
    name := file.basename
    for (i:=0; i<index.size; i++)
      if (name == index[i].toStr)
      {
        if (i > 0) prev = index[i-1]
        if (i < index.size-1) next = index[i+1]
        break;
      }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File file
  Doc? doc
  Uri? prev   // prev link if exists
  Uri? next   // next link if exists

}

class ListNode
{
  // TODO - this is not 100% correct - won't handle
  // non-linear heading levels
  static ListNode fromDocNodes(DocNode[] docNodes)
  {
    root  := ListNode()
    curr  := root
    last  := curr
    level := 1
    for (i:=0; i<docNodes.size; i++)
    {
      docNode := docNodes[i] as Heading
      if (docNode == null) continue
      if (docNode.level > level) { curr = last; level++ }
      while (docNode.level < level) { curr = curr.parent; level-- }
      last = ListNode { it.heading=docNode; it.parent=curr }
      curr.kids.add(last)
    }
    return root
  }

  Heading? heading
  ListNode? parent
  ListNode[] kids := ListNode[,]
}