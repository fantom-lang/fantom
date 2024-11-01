//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

**
** Extensions to enable certain features of Fandoc in markdown
**
@Js
class FandocExt : MarkdownExt
{
  override Void extendParser(ParserBuilder builder)
  {
    builder.customInlineContentParserFactory(SingleQuoteInlineParser.factory)
  }

  override Void extendRenderer(HtmlRendererBuilder builder)
  {
    builder.nodeRendererFactory |HtmlContext cx->NodeRenderer| { FandocRenderer(cx) }
  }
}

**************************************************************************
** FanCode
**************************************************************************

** Fandoc inline code block, e.g. ('this is code')
@Js
internal class FanCode : CustomNode
{
  new make(Str literal) { this.literal = literal }
  const Str literal
}

**************************************************************************
** SingleQuoteInlineParser
**************************************************************************

@Js
internal class SingleQuoteInlineParser : InlineContentParser
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
    return ParsedInline.of(FanCode(content), scanner.pos)
  }

  static const InlineContentParserFactory factory := SingleQuoteInlineParserFactory()
}

**************************************************************************
** SingleQuoteInlineParserFactory
**************************************************************************

@Js
internal const class SingleQuoteInlineParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['\'']

  override InlineContentParser create() { SingleQuoteInlineParser() }
}

**************************************************************************
** FandocRenderer
**************************************************************************

@Js
internal class FandocRenderer : NodeRenderer, Visitor
{
  new make(HtmlContext cx)
  {
    this.html = cx.writer
  }

  private HtmlWriter html

  override const Type[] nodeTypes := [FanCode#]

  override Void render(Node node) { node.walk(this) }

  override Void visitCustomNode(CustomNode node)
  {
    if (node is FanCode) visitFanCode(node)
    else throw ArgErr("Unexpected custom node: ${node.typeof}")
  }

  private Void visitFanCode(FanCode code)
  {
    html.tag("code").text(code.literal).tag("/code")
  }

}