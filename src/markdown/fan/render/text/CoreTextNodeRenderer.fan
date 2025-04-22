//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

**
** The node renderer that renders all the core nodes (comes last in the order
** of node renderers).
**
@Js
@NoDoc class CoreTextNodeRenderer : Visitor, NodeRenderer
{
  new make(TextContext cx)
  {
    this.cx = cx
    this.content = cx.writer
  }

  protected TextContext cx { private set }
  private TextWriter content
  private TextListHolder? listHolder

  private Bool stripNewLines() { cx.stripNewLines }

  override const Type[] nodeTypes := [
    Document#,
    Heading#,
    Paragraph#,
    BlockQuote#,
    BulletList#,
    FencedCode#,
    HtmlBlock#,
    ThematicBreak#,
    IndentedCode#,
    Link#,
    ListItem#,
    OrderedList#,
    Image#,
    Emphasis#,
    StrongEmphasis#,
    Text#,
    Code#,
    HtmlInline#,
    SoftLineBreak#,
    HardLineBreak#,
  ]

  override Void render(Node node) { node.walk(this) }

  override Void visitDocument(Document document)
  {
    // no rendering itself
    visitChildren(document)
  }

  override Void visitBlockQuote(BlockQuote blockQuote)
  {
    // left-pointing double angle quotation mark
    content.write("\u00AB")
    visitChildren(blockQuote)
    content.resetBlock
    // right-pointing double angle quotation mark
    content.write("\u00BB")

    content.block
  }

  override Void visitBulletList(BulletList bulletList)
  {
    content.pushTight(bulletList.tight)
    listHolder = TextListHolder(listHolder, bulletList)
    visitChildren(bulletList)
    content.popTight
    content.block
    listHolder = listHolder.parent
  }

  override Void visitCode(Code code)
  {
    content.writeChar('"').write(code.literal).writeChar('"')
  }

  override Void visitFencedCode(FencedCode code)
  {
    literal := code.literal
    if (literal[-1] == '\n') literal = literal[0..<-1]

    if (stripNewLines) content.writeStripped(literal)
    else content.write(literal)

    content.block
  }

  override Void visitHardLineBreak(HardLineBreak br)
  {
    if (stripNewLines) content.whitespace
    else content.line
  }

  override Void visitHeading(Heading heading)
  {
    visitChildren(heading)
    if (stripNewLines) content.write(": ")
    else content.block
  }

  override Void visitHtmlInline(HtmlInline html)
  {
    writeText(html.literal)
  }

  override Void visitHtmlBlock(HtmlBlock html)
  {
    writeText(html.literal)
  }

  override Void visitIndentedCode(IndentedCode code)
  {
    literal := code.literal
    if (literal[-1] == '\n') literal = literal[0..<-1]

    if (stripNewLines) content.writeStripped(literal)
    else content.write(literal)

    content.block
  }

  override Void visitThematicBreak(ThematicBreak tb)
  {
    if (!stripNewLines) content.write("***")
    content.block
  }

  override Void visitImage(Image image)
  {
    writeLink(image, image.title, image.destination)
  }

  override Void visitLink(Link link)
  {
    writeLink(link, link.title, link.destination)
  }

  override Void visitListItem(ListItem listItem)
  {
    if (listHolder != null && listHolder.isOrderedList)
    {
      indent := stripNewLines ? "" : listHolder.indent
      content.write("${indent}${listHolder.counter}${listHolder.delim} ")
      visitChildren(listItem)
      content.block
      listHolder.counter++
    }
    else
    {
      if (!stripNewLines)
        content.write("${listHolder.indent}${listHolder.marker} ")
      visitChildren(listItem)
      content.block
    }
  }

  override Void visitOrderedList(OrderedList orderedList)
  {
    content.pushTight(orderedList.tight)
    listHolder = TextListHolder(listHolder, orderedList)
    visitChildren(orderedList)
    content.popTight
    content.block
    listHolder = listHolder.parent
  }

  override Void visitParagraph(Paragraph p)
  {
    visitChildren(p)
    content.block
  }

  override Void visitSoftLineBreak(SoftLineBreak sb)
  {
    if (stripNewLines) content.whitespace
    else content.line
  }

  override Void visitText(Text text)
  {
    writeText(text.literal)
  }

  private Void writeText(Str text)
  {
    if (stripNewLines) content.writeStripped(text)
    else content.write(text)
  }

  private Void writeLink(Node node, Str? title, Str destination)
  {
    hasChild := node.firstChild != null
    hasTitle := title != null && (title != destination)
    hasDest  := !destination.isEmpty

    if (hasChild)
    {
      content.writeChar('"')
      visitChildren(node)
      content.writeChar('"')
      if (hasTitle || hasDest) content.whitespace.writeChar('(')
    }

    if (hasTitle)
    {
      content.write(title)
      if (hasDest) content.colon.whitespace
    }

    if (hasDest) content.write(destination)

    if (hasChild && (hasTitle || hasDest)) content.writeChar(')')
  }

  protected override Void visitChildren(Node parent)
  {
    node := parent.firstChild
    while (node != null)
    {
      next := node.next
      cx.render(node)
      node = next
    }

  }

}

**************************************************************************
** TextListHolder
**************************************************************************

@Js
internal class TextListHolder
{
  new make(TextListHolder? parent, ListBlock listBlock)
  {
    this.parent    = parent
    this.listBlock = listBlock
    this.indent    = (parent != null)
      ? parent.indent + indent_default
      : indent_empty

    if (isOrderedList)
    {
      this.counter = listBlock->startNumber ?: 1
    }
  }

  private static const Str indent_default := "   ";
  private static const Str indent_empty   := ""

  TextListHolder? parent { private set }
  ListBlock listBlock { private set }
  const Str indent
  Int counter

  Bool isOrderedList() { listBlock is OrderedList }
  Str marker() { listBlock-> marker }
  Str delim() { listBlock->markerDelim ?: "." }

}