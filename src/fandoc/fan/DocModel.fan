//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 07  Brian Frank  Creation
//

**************************************************************************
** DocNodeId
**************************************************************************

@Js
enum class DocNodeId
{
  text,
  doc,
  heading,
  para,
  pre,
  blockQuote,
  orderedList,
  unorderedList,
  listItem,
  emphasis,
  strong,
  code,
  link,
  image,
  hr
}

**************************************************************************
** Node
**************************************************************************

**
** DocNode is the base class for nodes in a fandoc model.
** There are two type of nodes:  DocElem and DocText.
**
** See [pod doc]`pod-doc#api` for usage.
**
@Js
abstract class DocNode
{
  **
  ** Get node id for node type.
  **
  abstract DocNodeId id()

  **
  ** Write this node to the specified DocWriter.
  **
  abstract Void write(DocWriter out)

  **
  ** Is this an inline versus a block node.
  **
  abstract Bool isInline()

  **
  ** Is this a block element versus an inline element.
  **
  Bool isBlock() { return !isInline }

  **
  ** Debug dump to output stream.
  **
  Void dump(OutStream out := Env.cur.out)
  {
    html := HtmlDocWriter(out)
    write(html)
    html.out.flush
  }

  //////////////////////////////////////////////////////////////////////////
  // Path Utilities
  //////////////////////////////////////////////////////////////////////////

  **
  ** Get the `DocElem` that contains this node.
  ** Return 'null' if not parented.
  **
  DocElem? parent { internal set }

  **
  ** Get the path from the root of the DOM to this node.
  **
  virtual DocNode[] path()
  {
    DocNode[] p := [this]
    cur := parent
    while (cur != null)
    {
      p.add(cur)
      cur = cur.parent
    }
    return p.reverse
  }

  **
  ** Get the index of this node in its parent's children.
  ** Return 'null' if not parented.
  **
  Int? pos()
  {
    return parent?.children?.indexSame(this)
  }

  **
  ** Return 'true' if this node is the first child in its parent.
  **
  Bool isFirst()
  {
    return pos == 0
  }

  **
  ** Return 'true' if this node is the last child in its parent.
  **
  Bool isLast()
  {
    return parent?.children?.last === this
  }

  **
  ** Get all the DocText children as a string
  **
  abstract Str toText()
}

**************************************************************************
** DocText
**************************************************************************

**
** DocText segment.
**
** See [pod doc]`pod-doc#api` for usage.
**
@Js
class DocText : DocNode
{
  new make(Str str) { this.str = str }

  override DocNodeId id() { return DocNodeId.text }

  override Void write(DocWriter out)
  {
    out.text(this)
  }

  override Bool isInline() { true }

  override Str toText() { str }

  override Str toStr() { str }

  Str str
}

**************************************************************************
** DocElem
**************************************************************************

**
** DocElem is a container node which models a branch of the doc tree.
**
** See [pod doc]`pod-doc#api` for usage.
**
@Js
abstract class DocElem : DocNode
{
  **
  ** Get the HTML element name to use for this element.
  **
  abstract Str htmlName()

  **
  ** Write this element and its children to the specified DocWriter.
  **
  override Void write(DocWriter out)
  {
    out.elemStart(this)
    writeChildren(out)
    out.elemEnd(this)
  }

  **
  ** Write this element's children to the specified DocWriter.
  **
  Void writeChildren(DocWriter out)
  {
    children.each |DocNode child| { child.write(out) }
  }

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** Get a readonly list of this elements's children.
  **
  DocNode[] children() { return kids.ro }

  **
  ** Iterate the children nodes
  **
  Void eachChild(|DocNode| f) { kids.each(f) }

  @Deprecated { msg = "Use add()" }
  This addChild(DocNode node) { add(node) }

  **
  ** Add a child to this node.  If adding a text node
  ** it is automatically merged with the trailing text
  ** node (if applicable).  If the node is arlready parented
  ** thorw ArgErr. Return this.
  **
  @Operator This add(DocNode node)
  {
    if (node.parent != null) throw ArgErr("Node already parented: $node")
    if (!kids.isEmpty)
    {
      last := kids.last

      // if adding two text nodes, then merge them
      if (node.id === DocNodeId.text && last.id === DocNodeId.text)
      {
        ((DocText)kids.last).str += ((DocText)node).str
        return this
      }

      // two consecutive blockquotes get merged
      if (node.id === DocNodeId.blockQuote && last.id == DocNodeId.blockQuote)
      {
        DocElem elem := (DocElem)node
        elem.kids.dup.each |child| { elem.remove(child); last->addChild(child) }
        return this
      }
    }

    node.parent = this
    kids.add(node)
    return this
  }

  **
  ** Insert a child node at the specified index. A negative index may be
  ** used to access an index from the end of the list. If adding a text node
  ** it is automatically merged with surrounding text nodes (if applicable).
  ** If the node is already parented throws ArgErr.
  **
  This insert(Int index, DocNode node)
  {
    tail := DocNode[node]
    kids.dup.eachRange(index..-1) |child| { remove(child); tail.add(child) }
    tail.each { add(it) }
    return this
  }

  **
  ** Convenicence to call `add` for each node in the given list.
  **
  This addAll(DocNode[] nodes)
  {
    nodes.each |node| { add(node) }
    return this
  }

  **
  ** Remove a child node. If this element is not the child's
  ** current parent throw ArgErr. Return this.
  **
  This remove(DocNode node)
  {
    if (kids.removeSame(node) == null) throw ArgErr("not my child: $node")
    node.parent = null
    return this
  }

  **
  ** Remove all child nodes. Return this.
  **
  This removeAll()
  {
    kids.dup.each |node| { remove(node) }
    return this
  }

  **
  ** Get all the DocText children as a string
  **
  override Str toText()
  {
    s := StrBuf()
    kids.each |kid| { s.join(kid.toText, " ") }
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Path
//////////////////////////////////////////////////////////////////////////

  **
  ** Covariant override to narrow path to list of `DocElem`.
  **
  final override DocElem[] path()
  {
    return super.path.map|n->DocElem| { (DocElem)n }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private DocNode[] kids := [,]
  Str? anchorId
}

**************************************************************************
** Doc
**************************************************************************

**
** Doc models the top level node of a fandoc document.
**
@Js
class Doc : DocElem
{
  override DocNodeId id() { return DocNodeId.doc }
  override Str htmlName() { return "body" }
  override Bool isInline() { return false }

  override Void write(DocWriter out)
  {
    out.docStart(this)
    super.write(out)
    out.docEnd(this)
  }

  **
  ** Recursively walk th document to build an order list of the
  ** multi-level headings which can serve as a "table of contents"
  ** for the document.
  **
  Heading[] findHeadings()
  {
    acc := Heading[,]
    doFindHeadings(acc, this)
    return acc
  }

  private Void doFindHeadings(Heading[] acc, DocElem elem)
  {
    if (elem is Heading) acc.add(elem)
    elem.children.each |kid| { if (kid is DocElem) doFindHeadings(acc, kid) }
  }

  Str:Str meta := Str:Str[:]
}

**************************************************************************
** Heading
**************************************************************************

**
** Heading
**
@Js
class Heading : DocElem
{
  new make(Int level) { this.level = level }
  override DocNodeId id() { return DocNodeId.heading }
  override Str htmlName() { return "h$level" }
  override Bool isInline() { return false }
  Str title() { toText }
  const Int level
}

**************************************************************************
** Para
**************************************************************************

**
** Para models a paragraph of text.
**
@Js
class Para : DocElem
{
  override DocNodeId id() { return DocNodeId.para }
  override Str htmlName() { return "p" }
  override Bool isInline() { return false }
  Str? admonition   // WARNING, NOTE, TODO, etc
}

**************************************************************************
** Pre
**************************************************************************

**
** Pre models a pre-formated code block.
**
@Js
class Pre : DocElem
{
  override DocNodeId id() { return DocNodeId.pre }
  override Str htmlName() { return "pre" }
  override Bool isInline() { return false }
}

**************************************************************************
** BlockQuote
**************************************************************************

**
** BlockQuote models a block of quoted text.
**
@Js
class BlockQuote : DocElem
{
  override DocNodeId id() { return DocNodeId.blockQuote }
  override Str htmlName() { return "blockquote" }
  override Bool isInline() { return false }
}

**************************************************************************
** OrderedList
**************************************************************************

**
** OrderedList models a numbered list
**
@Js
class OrderedList : DocElem
{
  new make(OrderedListStyle style) { this.style = style }
  override DocNodeId id() { return DocNodeId.orderedList }
  override Str htmlName() { return "ol" }
  override Bool isInline() { return false }
  OrderedListStyle style
}

**
** OrderedListStyle
**
@Js
enum class OrderedListStyle
{
  number,       // 1, 2, 3, 4
  upperAlpha,   // A, B, C, D
  lowerAlpha,   // a, b, c, d
  upperRoman,   // I, II, III, IV
  lowerRoman    // i, ii, iii, iv

  Str htmlType()
  {
    switch (this)
    {
      case number:     return "decimal"
      case upperAlpha: return "upper-alpha"
      case lowerAlpha: return "lower-alpha"
      case upperRoman: return "upper-roman"
      case lowerRoman: return "lower-roman"
      default: throw Err(toStr)
    }
  }

  static OrderedListStyle fromFirstChar(Int ch)
  {
    if (ch == 'I') return upperRoman
    if (ch == 'i') return lowerRoman
    if (ch.isUpper) return upperAlpha
    if (ch.isLower) return lowerAlpha
    return number
  }
}

**************************************************************************
** UnorderedList
**************************************************************************

**
** UnorderedList models a bullet list
**
@Js
class UnorderedList : DocElem
{
  override DocNodeId id() { return DocNodeId.unorderedList }
  override Str htmlName() { return "ul" }
  override Bool isInline() { return false }
}

**************************************************************************
** ListItem
**************************************************************************

**
** ListItem is an item in an OrderedList and UnorderedList.
**
@Js
class ListItem : DocElem
{
  override DocNodeId id() { return DocNodeId.listItem }
  override Str htmlName() { return "li" }
  override Bool isInline() { return false }
}

**************************************************************************
** Emphasis
**************************************************************************

**
** Emphasis is italic text
**
@Js
class Emphasis : DocElem
{
  override DocNodeId id() { return DocNodeId.emphasis }
  override Str htmlName() { return "em" }
  override Bool isInline() { return true }
}

**************************************************************************
** Strong
**************************************************************************

**
** Strong is bold text
**
@Js
class Strong : DocElem
{
  override DocNodeId id() { return DocNodeId.strong }
  override Str htmlName() { return "strong" }
  override Bool isInline() { return true }
}

**************************************************************************
** Code
**************************************************************************

**
** Code is inline code
**
@Js
class Code : DocElem
{
  override DocNodeId id() { return DocNodeId.code }
  override Str htmlName() { return "code" }
  override Bool isInline() { return true }
}

**************************************************************************
** Link
**************************************************************************

**
** Link is a hyperlink.
**
@Js
class Link : DocElem
{
  new make(Str uri) { this.uri = uri }
  override DocNodeId id() { return DocNodeId.link }
  override Str htmlName() { return "a" }
  override Bool isInline() { return true }

  ** Is the text of the link the same as the URI string
  Bool isTextUri() { children.first is DocText && children.first.toStr == this.uri }

  ** Change the text to display for the link
  Void setText(Str text) { removeAll.add(DocText(text)) }

  Bool isCode := false  // when uri resolves to a type or slot
  Str uri
  Int line
}

**************************************************************************
** Image
**************************************************************************

**
** Image is a reference to an image file
**
@Js
class Image : DocElem
{
  new make(Str uri, Str alt) { this.uri = uri; this.alt = alt  }
  override DocNodeId id() { return DocNodeId.image }
  override Str htmlName() { return "img" }
  override Bool isInline() { return true }
  Str uri
  Str alt
  Str? size  // formatted {w}x{h}
  Int line
}

**************************************************************************
** Hr
**************************************************************************

**
** Hr models a horizontal rule.
**
@Js
class Hr : DocElem
{
  override DocNodeId id() { return DocNodeId.hr }
  override Str htmlName() { return "hr" }
  override Bool isInline() { return false }
}