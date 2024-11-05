//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

**
** Extension to enable certain features of Fandoc in markdown, e.g. ('code')
**
@Js
@NoDoc const class FandocExt : MarkdownExt
{
  override Void extendParser(ParserBuilder builder)
  {
    builder
      .customInlineContentParserFactory(TicksInlineParser.factory)
      .customInlineContentParserFactory(BackticksLinkParser.factory)
  }

  override Void extendRenderer(HtmlRendererBuilder builder)
  {
    builder
      .nodeRendererFactory |HtmlContext cx->NodeRenderer| { TicksCodeRenderer(cx) }
  }
}

**************************************************************************
** TickCode
**************************************************************************

** Inline code using single-quote (tick) delimiters, e.g. 'this is code'
@Js
internal class TicksCode : CustomNode
{
  new make(Str literal) { this.literal = literal }
  const Str literal
}

**************************************************************************
** TickInlineParser
**************************************************************************

@Js
internal class TicksInlineParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    scanner := state.scanner
    // consume opening "'"
    scanner.next

    // consume code literal
    pos := scanner.pos
    if (scanner.find('\'') == -1) return ParsedInline.none
    content := scanner.source(pos, scanner.pos).content

    // consume closing "'"
    scanner.next
    return ParsedInline.of(TicksCode(content), scanner.pos)
  }

  static const InlineContentParserFactory factory := TicksInlineParserFactory()
}

@Js
internal const class TicksInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['\'']

  override InlineContentParser create() { TicksInlineParser() }
}

**************************************************************************
** TicksCodeRenderer
**************************************************************************

@Js
internal class TicksCodeRenderer : NodeRenderer, Visitor
{
  new make(HtmlContext cx)
  {
    this.html = cx.writer
  }

  private HtmlWriter html

  override const Type[] nodeTypes := [TicksCode#]

  override Void render(Node node) { node.walk(this) }

  virtual Void visitTicksCode(TicksCode code)
  {
    html.tag("code").text(code.literal).tag("/code")
  }
}

**************************************************************************
**
**************************************************************************

@Js
internal class BackticksLinkParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    // parse with normal backticks semantics
    res := BackticksInlineParser().tryParse(state)
    if (res == null) return res

    // convert to a Link
    Code code := res.node
    link := Link(code.literal).appendChild(Text(code.literal))
    return ParsedInline.of(link, res.pos)
  }

  static const InlineContentParserFactory factory := BackticksLinkParserFactory()
}

@Js
internal const class BackticksLinkParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['`']

  override InlineContentParser create() { BackticksLinkParser() }
}