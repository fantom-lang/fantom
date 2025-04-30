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
** html = Xetodoc.toHtml("Hello, 'Xetodoc'!")
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
  static Document parse(Str source, LinkResolver? linkResolver := null)
  {
    parser(linkResolver).parse(source)
  }

  ** Get a Xetodoc parser optionally configured with the given `LinkResolver`.
  ** Note that if the parser is re-used, the link resolver should be idempotent.
  static Parser parser(LinkResolver? linkResolver := null)
  {
    builder := parserBuilder
    if (linkResolver != null)
    {
      // need to wrap in unsafe to make the closure looks const
      unsafe := Unsafe(linkResolver)
      builder.postProcessorFactory |->LinkResolver| { unsafe.val }
    }
    return builder.build
  }

  ** Get a `ParserBuilder` with all the standard Xetodoc features enabled.
  static ParserBuilder parserBuilder()
  {
    Parser.builder.extensions(xetodoc)
  }

  ** Convenience to render the given Xetodoc to HTML
  static Str toHtml(Str source, LinkResolver? linkResolver := null)
  {
    htmlRenderer.render(parser(linkResolver).parse(source))
  }

  ** Convenience to render the given node to HTML
  static Str renderToHtml(Node node) { htmlRenderer.render(node) }

  ** Get a Xetodoc html renderer
  static const HtmlRenderer htmlRenderer := htmlBuilder.build

  ** Get an `HtmlRendererBuilder` with all the standard Xetodoc features enabled.
  static HtmlRendererBuilder htmlBuilder()
  {
    HtmlRenderer.builder
      .nodeRendererFactory |cx->NodeRenderer| { EmbedRenderer(cx) }
      .extensions(xetodoc)
  }

  ** Convenience to render parsed AST back to Xetodoc markdown text
  Str renderToMarkdown(Node node) { markdownRenderer.render(node) }

  ** Get a Xetodoc markdown renderer
  static const MarkdownRenderer markdownRenderer := markdownBuilder.build

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
    builder
      .attrProviderFactory |HtmlContext cx->AttrProvider| { HeadingAttrsProvider() }
      .extensions(exts)
  }

  override Void extendMarkdown(MarkdownRendererBuilder builder)
  {
    builder
      .nodeRendererFactory(|cx->NodeRenderer| { MdTicksRenderer(cx) })
      .extensions(exts)
  }
}

**************************************************************************
** HeadingAttrsProvider
**************************************************************************

@Js
internal class HeadingAttrsProvider : AttrProvider
{
  override Void setAttrs(Node node, Str tagName, [Str:Str?] attrs)
  {
    if (node is Heading) attrs["id"] = ((Heading)node).anchor
  }
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
** BackticksLinkParser
**************************************************************************

**
** Parses '`url`' as a link as though it had been specified using
** the equivalent common markdown: '[url](/url)'. Note - only single-backticks
** will be parsed as links, e.g. '``not a link``'
**
** Has special handling for `embed://` links
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
    dest := code.literal
    uri  := dest.toUri
    link := uri.scheme == "embed" ? Embed(dest) : Link(dest).appendChild(Text(dest))
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
** Embedded Video
**************************************************************************

**
** A link to a video. Supported uris for the video are
** - Loom: 'embed://loom/<id>?sid=<sid>'
** - YouTube: 'embed://youtu.be/<id>?si=<si>' or 'embed://youtube/<id>?si=<si>'
**
** You may specify additional query params and those will be applied as attributes
** to the rendered iframe in HTML
**
@Js
internal class Embed : LinkNode
{
  new make(Str destination) : super(destination)
  {
    this.uri = destination.toUri
  }
  const Uri uri
}

@Js
internal class EmbedRenderer : NodeRenderer
{
  new make(HtmlContext cx)
  {
    this.cx = cx
    this.html = cx.writer
  }

  private HtmlContext cx
  private HtmlWriter html

  override const Type[] nodeTypes := [Embed#]
  private const [Str:Str?] stdAttrs := [
    "frameborder": "0",
    "allowfullscreen": null,
    "webkitallowfullscreen": null,
    "mozallowfullscreen": null,
    "width": "50%",
    "height": "35%",
  ]

  override Void render(Node node)
  {
    embed := (Embed)node
    type  := embed.uri.host.lower
    switch (type)
    {
      case "loom": renderLoom(embed)
      // case "vimeo": renderVimeo(embed)
      case "youtube":
      case "youtu.be":
        renderYoutube(embed)
      default: throw UnsupportedErr("Cannot embed '${type}'")
    }
  }

  private Void renderLoom(Embed embed)
  {
    uri := embed.uri
    id  := uri.path.last.trimToNull ?: throw ParseErr("Invalid loom uri: ${uri}")
    sid := uri.query["sid"] ?: throw ParseErr("Invalid loom uri: ${uri}")
    src := `https://www.loom.com/embed/${id}?sid=${sid}`
    attrs := stdAttrs.dup.addAll(["title": "Loom", "src": "${src}"]).setAll(uri.query)
    renderEmbedded(attrs)
  }

  private Void renderYoutube(Embed embed)
  {
    uri := embed.uri
    id  := uri.path.getSafe(0) ?: throw ParseErr("Invalid youtube uri: ${uri}")
    si  := uri.query["si"] ?: throw ParseErr("Invalid youtube uri: ${uri}")
    src := `https://www.youtube.com/embed/${id}?si=${si}`
    attrs := stdAttrs.dup.addAll([
      "title":"YouTube",
      "src":"${src}",
      "allow":"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; webshare",
      "referrerpolicy": "strict-origin-when-cross-origin",
    ]).setAll(uri.query)
    renderEmbedded(attrs)
  }

  private Void renderEmbedded([Str:Str?] attrs)
  {
    html.line
    html.tag("div")
    html.tag("iframe", attrs).tag("/iframe")
    html.tag("/div")
  }
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