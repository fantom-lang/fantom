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
  image
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
  ** Debug dump to output stream.
  **
  Void dump(OutStream out := Env.cur.out)
  {
    html := HtmlDocWriter(out)
    write(html)
    html.out.flush
  }
}

**************************************************************************
** DocText
**************************************************************************

**
** DocText segment.
**
** See [pod doc]`pod-doc#api` for usage.
**
class DocText : DocNode
{
  new make(Str str) { this.str = str }

  override DocNodeId id() { return DocNodeId.text }

  override Void write(DocWriter out)
  {
    out.text(this)
  }

  override Str toStr() { return str }

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
abstract class DocElem : DocNode
{
  **
  ** Get the HTML element name to use for this element.
  **
  abstract Str htmlName()

  **
  ** Is this an inline versus a block element.
  **
  abstract Bool isInline()

  **
  ** Is this a block element versus an inline element.
  **
  Bool isBlock() { return !isInline }

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

  **
  ** Add a child to this node.  If adding a text node
  ** it is automatically merged with the trailing text
  ** node (if applicable).  Return this.
  **
  This addChild(DocNode node)
  {
    if (!children.isEmpty)
    {
      last := children.last

      // if adding two text nodes, then merge them
      if (node.id === DocNodeId.text && last.id === DocNodeId.text)
      {
        ((DocText)children.last).str += ((DocText)node).str
        return this
      }

      // two consecutive blockquotes get merged
      if (node.id === DocNodeId.blockQuote && last.id == DocNodeId.blockQuote)
      {
        ((DocElem)last).children.addAll(((DocElem)node).children)
        return this
      }
    }

    children.add(node)
    return this
  }

  DocNode[] children := DocNode[,]
  Str? anchorId
}

**************************************************************************
** Doc
**************************************************************************

**
** Doc models the top level node of a fandoc document.
**
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

  Str:Str meta := Str:Str[:]
}

**************************************************************************
** Heading
**************************************************************************

**
** Heading
**
class Heading : DocElem
{
  new make(Int level) { this.level = level }
  override DocNodeId id() { return DocNodeId.heading }
  override Str htmlName() { return "h$level" }
  override Bool isInline() { return false }
  const Int level
}

**************************************************************************
** Para
**************************************************************************

**
** Para models a paragraph of text.
**
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
class Link : DocElem
{
  new make(Str uri) { this.uri = uri }
  override DocNodeId id() { return DocNodeId.link }
  override Str htmlName() { return "a" }
  override Bool isInline() { return true }
  Bool isCode := false  // when uri resolves to a type or slot
  Str uri
}

**************************************************************************
** Image
**************************************************************************

**
** Image is a reference to an image file
**
class Image : DocElem
{
  new make(Str uri, Str alt) { this.uri = uri; this.alt = alt  }
  override DocNodeId id() { return DocNodeId.image }
  override Str htmlName() { return "img" }
  override Bool isInline() { return true }
  Str uri
  Str alt
}

