//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Oct 2024  Matthew Giannini  Creation
//

** The node renderer that renders all the core nodes
** (comes last in the order of renderers)
@Js
@NoDoc class CoreHtmlNodeRenderer : Visitor, NodeRenderer
{
  new make(HtmlContext cx)
  {
    this.cx = cx
    this.html = cx.writer
  }

  protected HtmlContext cx { private set }
  private HtmlWriter html

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
  }

  override Void visitHeading(Heading heading)
  {
    htag := "h${heading.level}"
    html.line
      .tag(htag, attrs(heading, htag))
    visitChildren(heading)
    html.tag("/${htag}")
      .line
  }

  override Void visitParagraph(Paragraph p)
  {
    omitP := isInTightList(p) ||
      (cx.omitSingleParagraphP && p.parent is Document &&
        p.prev == null && p.next == null)

    if (!omitP)
    {
      html.line
      html.tag("p", attrs(p, "p"))
    }
    visitChildren(p)
    if (!omitP)
    {
      html.tag("/p").line
    }
  }

  override Void visitBlockQuote(BlockQuote bq)
  {
    html.line
      .tag("blockquote", attrs(bq, "blockquote"))
      .line
    visitChildren(bq)
    html.line
      .tag("/blockquote")
      .line
  }

  override Void visitBulletList(BulletList list)
  {
    renderListBlock(list, "ul", attrs(list, "ul"))
  }

  override Void visitOrderedList(OrderedList list)
  {
    start := list.startNumber ?: 1
    attrs := newAttrs
    if (start != 1) attrs["start"] = "${start}"
    renderListBlock(list, "ol", this.attrs(list, "ol", attrs))
  }

  override Void visitListItem(ListItem item)
  {
    html.tag("li", attrs(item, "li"))
    visitChildren(item)
    html.tag("/li")
    html.line
  }

  override Void visitFencedCode(FencedCode code)
  {
    literal := code.literal
    info := code.info
    attrs := newAttrs
    if (info != null && !info.isEmpty)
    {
      sp := info.index(" ")
      Str? lang := null
      if (sp == null) lang = info
      else lang = info[0..<sp]
      attrs["class"] = "language-${lang}"
    }
    renderCodeBlock(literal, code, attrs)
  }

  override Void visitHtmlBlock(HtmlBlock block)
  {
    html.line
    if (cx.escapeHtml)
    {
      html.tag("p", attrs(block, "p"))
      html.text(block.literal)
      html.tag("/p")
    }
    else html.raw(block.literal)
    html.line
  }

  override Void visitThematicBreak(ThematicBreak tb)
  {
    html.line
      .tag("hr", attrs(tb, "hr"), true)
      .line
  }

  override Void visitIndentedCode(IndentedCode code)
  {
    renderCodeBlock(code.literal, code, [:])
  }

  override Void visitLink(Link link)
  {
    // if link is code wrap it in <code> tag
    if (link.isCode) html.tag("code")

    attrs := newAttrs
    url := link.destination

    if (cx.sanitizeUrls)
    {
      url = cx.urlSanitizer.sanitizeLink(url)
      attrs["rel"] = "nofollow"
    }

    url = cx.encodeUrl(url)
    attrs["href"] = url
    if (link.title != null) attrs["title"] = link.title
    html.tag("a", this.attrs(link, "a", attrs))
    visitChildren(link)
    html.tag("/a")

    // if link is code finish wrapping in </code> tag
    if (link.isCode) html.tag("/code")
  }

  override Void visitImage(Image image)
  {
    url := image.destination

    atv := AltTextVisitor()
    image.walk(atv)
    altText := atv.altText

    attrs := newAttrs
    if (cx.sanitizeUrls)
    {
      url = cx.urlSanitizer.sanitizeLink(url)
    }

    attrs["src"] = cx.encodeUrl(url)
    attrs["alt"] = altText
    if (image.title != null) attrs["title"] = image.title

    html.tag("img", this.attrs(image, "img", attrs), true)
  }

  override Void visitEmphasis(Emphasis emph)
  {
    html.tag("em", attrs(emph, "em"))
    visitChildren(emph)
    html.tag("/em")
  }

  override Void visitStrongEmphasis(StrongEmphasis strong)
  {
    html.tag("strong", attrs(strong, "strong"))
    visitChildren(strong)
    html.tag("/strong")
  }

  override Void visitText(Text text)
  {
    html.text(text.literal)
  }

  override Void visitCode(Code code)
  {
    html.tag("code", attrs(code, "code"))
      .text(code.literal)
      .tag("/code")
  }

  override Void visitHtmlInline(HtmlInline inline)
  {
    if (cx.escapeHtml)
      html.text(inline.literal)
    else
      html.raw(inline.literal)
  }

  override Void visitSoftLineBreak(SoftLineBreak node)
  {
    html.raw(cx.softbreak)
  }

  override Void visitHardLineBreak(HardLineBreak node)
  {
    html.tag("br", attrs(node, "br"), true)
    html.line
  }

  override protected Void visitChildren(Node parent)
  {
    // echo("visitChildren ${parent} ${Node.children(parent)}")
    node := parent.firstChild
    while (node != null)
    {
      next := node.next
      cx.render(node)
      node = next
    }
  }

  private Void renderCodeBlock(Str literal, Node node, [Str:Str] attrs)
  {
    html.line
      .tag("pre", this.attrs(node, "pre"))
      .tag("code", this.attrs(node, "code", attrs))
      .text(literal)
      .tag("/code")
      .tag("/pre")
      .line
  }

  private Void renderListBlock(ListBlock list, Str tagName, [Str:Str?]? attrs)
  {
    html.line
      .tag(tagName, attrs)
      .line
    visitChildren(list)
    html.line
      .tag("/${tagName}")
      .line
  }

  private Bool isInTightList(Paragraph p)
  {
    parent := p.parent
    if (parent != null)
    {
      gramps := parent.parent
      if (gramps is ListBlock)
      {
        isTight := ((ListBlock)gramps).tight
        return ((ListBlock)gramps).tight
      }
    }
    return false
  }

  [Str:Str] attrs(Node node, Str tagName, [Str:Str] defAttrs := newAttrs)
  {
    cx.extendAttrs(node, tagName, defAttrs)
  }

  protected [Str:Str] newAttrs() { [Str:Str][:] { ordered = true } }
}

**************************************************************************
** AltTextVisitor
**************************************************************************

@Js
internal class AltTextVisitor : Visitor
{
  private StrBuf sb := StrBuf()

  Str altText() { sb.toStr }

  override Void visitText(Text text) { sb.add(text.literal) }
  override Void visitSoftLineBreak(SoftLineBreak node) { sb.addChar('\n') }
  override Void visitHardLineBreak(HardLineBreak node) { sb.addChar('\n') }
}