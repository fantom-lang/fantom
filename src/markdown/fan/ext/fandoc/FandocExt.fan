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
internal class TicksInlineParser : InlineCodeParser
{
  new make() : super('\'') { }

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
** BackticksLinkParser
**************************************************************************

**
** Parses '`url`' as a link as though it had been specified using
** the equivalent common markdown: '[url](/url)'. Note - only single-backticks
** will be parsed as links, e.g. '``not a link``'
**
@Js
internal class BackticksLinkParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    // parse with normal backticks semantics (only support single opener/closer sequence)
    res := BackticksInlineParser().withMaxMarkers(1).tryParse(state)
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