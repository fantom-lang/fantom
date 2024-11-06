//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

@Js
@NoDoc class CoreMarkdownNodeRenderer : Visitor, NodeRenderer
{

  private static const Regex orderedListMarkerPattern := Regex("^([0-9]{1,9})([.)])")

  new make(MarkdownContext cx)
  {
    this.cx = cx
    this.writer = cx.writer

    this.textEsc = |Int c->Bool| {
      if ("[]<>`*_&\n\\".containsChar(c)) return true
      if (cx.specialChars.contains(c)) return true
      return false
    }
    this.textEscInHeading = |Int c->Bool| { textEsc(c) || c == '#' }
  }

  protected MarkdownContext cx { private set }
  private MarkdownWriter writer

  private ListHolder? listHolder

  private |Int->Bool| textEsc
  private |Int->Bool| textEscInHeading
  private static const |Int->Bool| linkDestNeedsAngleBrackets := |c->Bool| {
    switch (c)
    {
      case ' ':
      case '(':
      case ')':
      case '<':
      case '>':
      case '\n':
      case '\\':
        // fall-through
        return true
      default:
        return false
    }
  }
  private static const |Int->Bool| linkDestEscInAngleBrackets := |c->Bool| {
    c == '<' || c == '>' || c == '\n' || c =='\\'
  }
  private static const |Int->Bool| linkTitleEscInQuotes := |c->Bool| {
    c == '"' || c == '\n' || c == '\\'
  }

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

  override Void visitDocument(Document doc)
  {
    // no rendering itself
    visitChildren(doc)
    writer.line
  }

  override Void visitThematicBreak(ThematicBreak tb)
  {
    literal := tb.literal
    if (literal == null)
    {
      // let's use ___ as it doesn't introduce ambiguity with * or - list item markers
      literal = "___"
    }
    writer.raw(literal)
    writer.block
  }

  override Void visitHeading(Heading heading)
  {
    if (heading.level <= 2)
    {
      lineBreakVisitor := LineBreakVisitor()
      heading.walk(lineBreakVisitor)
      isMultiLine := lineBreakVisitor.hasLineBreak

      if (isMultiLine)
      {
        // setext headings: can have multiple lines, but only level 1 or 2
        visitChildren(heading)
        writer.line
        if (heading.level == 1)
        {
          // note taht it would be nice to match the length of the contents instead of
          // just using 3, but that's not easy
          writer.raw("===")
        }
        else
        {
          writer.raw("---")
        }
        writer.block
        return
      }
    }

    // ATX headings: can't have multiple lines, but up to level 6
    heading.level.times { writer.raw('#') }
    writer.raw(' ')
    visitChildren(heading)

    writer.block
  }

  override Void visitBlockQuote(BlockQuote quote)
  {
    writer.writePrefix("> ")
    writer.pushPrefix("> ")
    visitChildren(quote)
    writer.popPrefix
    writer.block
  }

  override Void visitBulletList(BulletList list)
  {
    writer.pushTight(list.tight)
    listHolder = BulletListHolder(listHolder, list)
    visitChildren(list)
    listHolder = listHolder.parent
    writer.popTight
    writer.block
  }

  override Void visitOrderedList(OrderedList list)
  {
    writer.pushTight(list.tight)
    listHolder = OrderedListHolder(listHolder, list)
    visitChildren(list)
    listHolder = listHolder.parent
    writer.popTight
    writer.block
  }

  override Void visitListItem(ListItem item)
  {
    markerIndent := item.markerIndent ?: 0
    Str? marker := null
    if (listHolder is BulletListHolder)
    {
      marker = " ".mult(markerIndent) + ((BulletListHolder)listHolder).marker
    }
    else if (listHolder is OrderedListHolder)
    {
      list := (OrderedListHolder)listHolder
      marker = " ".mult(markerIndent) + "${list.number}${list.delim}"
      list.number++
    }
    else throw ArgErr("listHolder is ${listHolder}")

    contentIndent := item.contentIndent
    spaces := contentIndent == null ? " " : " ".mult(contentIndent - marker.size)
    writer.writePrefix(marker)
    writer.writePrefix(spaces)
    writer.pushPrefix(" ".mult(marker.size + spaces.size))

    if (item.firstChild == null) writer.block
    else visitChildren(item)

    writer.popPrefix
  }

  override Void visitFencedCode(FencedCode code)
  {
    literal := code.literal
    fenceChar := code.fenceChar ?: "`"
    openingFenceLen := 0
    if (code.openingFenceLen != null)
    {
      // if we have a known fence length, use it
      openingFenceLen = code.openingFenceLen
    }
    else
    {
      // otherwise, calculate the closing fence length pessimistically, e.g. if the
      // code block iteself contains a line with ```, we need to use a fence of length 4.
      // If ``` occurs with non-whitespace characters on a line, we technically don't need
      // a longer fence, but itsn' not incorrect to do so
      fenceCharsInLiteral := findMaxRunLen(fenceChar, literal)
      openingFenceLen = 3.max(fenceCharsInLiteral+1)
    }
    closingFenceLen := code.closingFenceLen ?: openingFenceLen

    openingFence := fenceChar.mult(openingFenceLen)
    closingFence := fenceChar.mult(closingFenceLen)
    indent := code.fenceIndent

    if (indent > 0)
    {
      indentPrefix := " ".mult(indent)
      writer.writePrefix(indentPrefix)
      writer.pushPrefix(indentPrefix)
    }

    writer.raw(openingFence)
    if (code.info != null) writer.raw(code.info)

    writer.line
    if (!literal.isEmpty)
    {
      getLines(literal).each |line| { writer.raw(line); writer.line }
    }
    writer.raw(closingFence)
    if (indent > 0) writer.popPrefix
    writer.block
  }

  override Void visitIndentedCode(IndentedCode code)
  {
    literal := code.literal
    // we need to respect line prefixes which is why we need to write it line by line
    // (e.g. an indented code block within a block quote)
    writer.writePrefix("    ")
    writer.pushPrefix("    ")
    lines := getLines(literal)
    lines.each |line, i|
    {
      writer.raw(line)
      if (i != lines.size - 1) writer.line
    }
    writer.popPrefix
    writer.block
  }

  override Void visitHtmlBlock(HtmlBlock html)
  {
    lines := getLines(html.literal)
    lines.each |line, i|
    {
      writer.raw(line)
      if (i != lines.size -1) writer.line
    }
    writer.block
  }

  override Void visitParagraph(Paragraph p)
  {
    visitChildren(p)
    writer.block
  }

  override Void visitLink(Link link)
  {
    writeLinkLike(link.title, link.destination, link, "[")
  }

  override Void visitImage(Image image)
  {
    writeLinkLike(image.title, image.destination, image, "![")
  }

  private Void writeLinkLike(Str? title, Str dest, Node node, Str opener)
  {
    writer.raw(opener)
    visitChildren(node)
    writer.raw(']')
    writer.raw('(')
    if (dest.any(linkDestNeedsAngleBrackets))
    {
      writer.raw('<')
      writer.text(dest, linkDestEscInAngleBrackets)
      writer.raw('>')
    }
    else writer.raw(dest)
    if (title != null)
    {
      writer.raw(' ')
      writer.raw('"')
      writer.text(title, linkTitleEscInQuotes)
      writer.raw('"')
    }
    writer.raw(')')
  }

  override Void visitEmphasis(Emphasis emp)
  {
    delim := emp.openingDelim
    // currently the parser always knows the opening delim
    // // use delimiter that was parsed if available
    // if (delim == null)
    // {
    //   // when emphasis is nested, a different delimiter needs to be used
    //   delim = writer.lastChar == "*" ? "_" : "*"
    // }
    writer.raw(delim)
    visitChildren(emp)
    writer.raw(delim)
  }

  override Void visitStrongEmphasis(StrongEmphasis strong)
  {
    writer.raw("**")
    visitChildren(strong)
    writer.raw("**")
  }

  override Void visitCode(Code code)
  {
    literal := code.literal
    // if the literal includes backticks, we can surround them by using one more backtick
    backticks := findMaxRunLen("`", literal)
    (backticks+1).times { writer.raw('`') }
    // if the literal starts or ends with a backtick, surround it with a single space.
    // if it starts and ends with a space (but is not only spaces), add an additonal space
    // otherwise they would get removed on parsing).
    addSpace := literal.startsWith("`") || literal.endsWith("`") ||
      (literal.startsWith(" ") && literal.endsWith(" ") && Chars.hasNonSpace(literal))
    if (addSpace) writer.raw(' ')
    writer.raw(literal)
    if (addSpace) writer.raw(' ')
    (backticks+1).times { writer.raw('`') }
  }

  override Void visitHtmlInline(HtmlInline html)
  {
    writer.raw(html.literal)
  }

  override Void visitHardLineBreak(HardLineBreak hard)
  {
    writer.raw("  ")
    writer.line
  }

  override Void visitSoftLineBreak(SoftLineBreak soft)
  {
    writer.line
  }

  override Void visitText(Text text)
  {
    // Text is tricky. In Markdown special characters ('-', '#', etc) can be escaped
    // ('\-', '\#', etc.) so that they're parsed as plain text. Currently, whether
    // a character was escaped or not is not recorded in the Node,
    // so here we don't know. If we just wrote out those characters unescaped, the
    // resulting Markdown would change meaning (turn into a list item, heading, etc.).
    //
    // You might say, "Why not sotre that in the Node when parsing", but that wouldn't
    // work for the use case where nodes are constructed directly instead of via parsing.
    // This renderer needs to work for that too.
    //
    // So currently, when in doubt, we escape. For special characters only occurring
    // at the beginning of a line, we only escape them then (we wouldn't want to escape
    // every '.' for example).
    literal := text.literal
    if (writer.atLineStart && !literal.isEmpty)
    {
      c := literal[0]
      switch (c)
      {
        case '-':
          // would be ambiguous with a bullet list marker, escape
          writer.raw("\\-")
          literal = literal[1..-1]
        case '#':
          // would be ambiguous with an ATX heading, escape
          writer.raw("\\#")
          literal = literal[1..-1]
        case '=':
          // would be ambiguous with a Setext heading, escape unless it's the first line block
          if (text.prev != null)
          {
            writer.raw("\\=")
            literal = literal[1..-1]
          }
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
          // fall-through
          // check for ordered list marker
          m := orderedListMarkerPattern.matcher(literal)
          if (m.find)
          {
            writer.raw(m.group(1))
            writer.raw("\\${m.group(2)}")
            literal = literal[m.end..-1]
          }
        case '\t':
          writer.raw("&#9;")
          literal = literal[1..-1]
        case ' ':
          writer.raw("&#32;")
          literal = literal[1..-1]
      }
    }

    escape := text.parent is Heading ? textEscInHeading : textEsc

    if (literal.endsWith("!") && text.next is Link)
    {
      // if we wrote the '!' unescaped, it would turn the link into an image instead
      writer.text(literal[0..<-1], escape)
      writer.raw("\\!")
    }
    else writer.text(literal, escape)
  }

  private static Str[] getLines(Str literal)
  {
    // use -1 so that split returns trailing empty strings, i.e. we want
    // "abc\n\n" to return ["abc", "", ""]
    parts := Regex("\n").split(literal, -1)
    if (parts.last.isEmpty)
    {
      // but we don't want the last empty string, as "\n" is used as a line terminator
      // (not a separator), so return with the last element
      return parts[0..<-1]
    }
    return parts
  }

  private static Int findMaxRunLen(Str needle, Str s)
  {
    maxRunLen := 0
    Int? pos := 0
    while (pos < s.size)
    {
      pos = s.index(needle, pos)
      if (pos == null) return maxRunLen
      runLen := 0
      while (true)
      {
        pos += needle.size
        ++runLen
        if (s.index(needle, pos) != pos) break
      }
      maxRunLen = runLen.max(maxRunLen)
    }
    return maxRunLen
  }

  override protected Void visitChildren(Node parent) { renderChildren(parent) }

  private Void renderChildren(Node parent)
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
** ListHolder
**************************************************************************

@Js
internal class ListHolder
{
  new make(ListHolder? parent) { this.parent = parent }
  ListHolder? parent { private set }
}

@Js
internal class BulletListHolder : ListHolder
{
  new make(ListHolder? parent, BulletList list) : super(parent)
  {
    this.marker = list.marker ?: "-"
  }
  const Str marker
}

@Js
internal class OrderedListHolder : ListHolder
{
  new make(ListHolder? parent, OrderedList list) : super(parent)
  {
    this.delim = list.markerDelim ?: "."
    this.number = list.startNumber ?: 1
  }
  const Str delim
  Int number
}

**************************************************************************
** LineBreakVisitor
**************************************************************************

@Js
internal class LineBreakVisitor : Visitor
{
  Bool hasLineBreak := false { private set }
  override Void visitSoftLineBreak(SoftLineBreak b)
  { visitChildren(b); this.hasLineBreak = true }
  override Void visitHardLineBreak(HardLineBreak b)
  { visitChildren(b); this.hasLineBreak = true }
}