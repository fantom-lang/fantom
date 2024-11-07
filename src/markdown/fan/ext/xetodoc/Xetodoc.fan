//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

**
** Xetodoc is a curated set of features and extensions to the CommonMark syntax.
**
** - Changes inline code to be single-tick delimited, e.g.
** pre>
** 'this is code'
** <pre
** - Allows links to be specified in backticks, e.g. '`http://fantom.org`'
** - Enables the following extensions: `ImgAttrsExt`, and `TablesExt`
**
** pre>
** parser := Xetodoc.parser |->LinkResolver| { MyCustomLinkResolver() }
** renderer := Xetodoc.htmlRenderer
** html := renderer.render(parser.parse("Hello 'Xetodoc'!"))
**
** // using convenience methods
** html = Xetodoc.renderToHtml("Hello, 'Xetodoc'!")
**
** // roundtrip the parsed Document back to xetodoc markdown text
** md := Xetodoc.renderToMarkdown(parser.parse("Round-trip to markdown"))
** <pre
**
@Js
@NoDoc const class Xetodoc : MarkdownExt
{
  ** Extensions automatically enabled by Xetodoc
  private static const MarkdownExt[] exts := [ImgAttrsExt(), TablesExt()]
  private static const MarkdownExt[] xetodoc := [Xetodoc()]

  ** Convenience to parse the Xetodoc source
  static Document parse(Str source, |->LinkResolver|? f := null)
  {
    parser(f).parse(source)
  }

  ** Get a Xetodoc parser optionally configured with the given `LinkResolver` factory
  static Parser parser(|->LinkResolver|? f := null)
  {
    builder := parserBuilder
    if (f != null) builder.postProcessorFactory(f)
    return builder.build
  }

  ** Get a `ParserBuilder` with all the standard Xetodoc features enabled.
  static ParserBuilder parserBuilder()
  {
    Parser.builder.extensions(xetodoc)
  }

  ** Convenience to render the given Xetodoc to HTML
  static Str renderToHtml(Str source, |->LinkResolver|? f := null)
  {
    htmlRenderer.render(parser(f).parse(source))
  }

  ** Get a Xetodoc html renderer
  static HtmlRenderer htmlRenderer() { htmlBuilder.build }

  ** Get an `HtmlRendererBuilder` with all the standard Xetodoc features enabled.
  static HtmlRendererBuilder htmlBuilder()
  {
    HtmlRenderer.builder.extensions(xetodoc)
  }

  ** Convenience to render parsed AST back to Xetodoc markdown text
  Str renderToMarkdown(Node node) { markdownRenderer.render(node) }

  ** Get a Xetodoc markdown renderer
  static MarkdownRenderer markdownRenderer() { markdownBuilder.build }

  ** Get a `MarkdownRendererBuilder` with all the standard Xetodoc features enabled.
  static MarkdownRendererBuilder markdownBuilder()
  {
    MarkdownRenderer.builder.extensions(xetodoc)
  }

//////////////////////////////////////////////////////////////////////////
// MarkdownExt
//////////////////////////////////////////////////////////////////////////

  override Void extendParser(ParserBuilder builder)
  {
    builder
      .customInlineContentParserFactory(TicksInlineParser.factory)
      .customInlineContentParserFactory(BackticksLinkParser.factory)
      .extensions(exts)
  }

  override Void extendHtml(HtmlRendererBuilder builder)
  {
    builder.extensions(exts)
  }

  override Void extendMarkdown(MarkdownRendererBuilder builder)
  {
    builder
      .nodeRendererFactory(|cx->NodeRenderer| { MdTicksRenderer(cx) })
      .extensions(exts)
  }
}

// **************************************************************************
// ** FandocExt
// **************************************************************************

// **
// ** The Fandoc extension modifies the parser so that single-ticks (') are the delimiter
// ** for inline code (e.g. 'code'), and backticks can be used to create links,
// ** (e.g. `http://fantom.org`)
// **
// ** This is nodoc extension that is used by `Xetodoc` to enable these features as
// ** part of the suite of features enabled in that mode.
// **
// @Js
// @NoDoc const class FandocExt : MarkdownExt
// {
//   override Void extendParser(ParserBuilder builder)
//   {
//     builder
//       .customInlineContentParserFactory(TicksInlineParser.factory)
//       .customInlineContentParserFactory(BackticksLinkParser.factory)
//   }

//   override Void extendMarkdown(MarkdownRendererBuilder builder)
//   {
//     builder.nodeRendererFactory(|cx->NodeRenderer| { MdTicksRenderer(cx) })
//   }
// }

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

**************************************************************************
** MdTicksRenderer
**************************************************************************

@Js
internal class MdTicksRenderer : NodeRenderer
{
  new make(MarkdownContext cx) { this.cx = cx }
  private MarkdownContext cx
  override const Type[] nodeTypes := [Code#]
  override Void render(Node node)
  {
    CoreMarkdownNodeRenderer.writeCode(cx.writer, node, '\'')
  }
}