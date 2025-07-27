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
** - Disables rendering of inline and block HTML nodes
** - Allows links to be specified in backticks, e.g. '`http://fantom.org`'
** - Enables the following extensions: `ImgAttrsExt`, and `TablesExt`
** - Enables embedding videos in HTML using image links using video scheme links
**   - ![alt text](video://youtu.be/abc?si=123)
**   - ![alt text](video://loom/def?sid=456)
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
    Parser.builder
      .withIncludeSourceSpans(IncludeSourceSpans.blocks_and_inlines)
      .linkProcessor(VideoProcessor())
      .extensions(xetodoc)
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
      .withDisableHtml
      .nodeRendererFactory |cx->NodeRenderer| { VideoRenderer(cx) }
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
      .customInlineContentParserFactory(BackticksSpecLinkParser.factory)
      .customInlineContentParserFactory(BackticksLinkParser.factory)
      .extensions(exts)
  }

  override Void extendHtml(HtmlRendererBuilder builder)
  {
    builder
      .attrProviderFactory |HtmlContext cx->AttrProvider| { HeadingAttrsProvider() }
      .nodeRendererFactory |cx->NodeRenderer| { SpecLinkRenderer(cx) }
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
** Only processes actual URLs, everything else becomes regular code
**
@Js
internal class BackticksLinkParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    // parse with normal backticks semantics (only support single opener/closer sequence)
    res := BackticksInlineParser().withMaxMarkers(1).tryParse(state)
    if (res == null) return res

    // check if this looks like a URL
    Code code := res.node
    content := code.literal
    
    // Only convert to link if it looks like a URL (contains :// or starts with http/https)
    if (!isUrl(content)) return null
    
    // convert to a Link
    link := Link(content).appendChild(Text(content))
    return ParsedInline.of(link, res.pos)
  }
  
  private Bool isUrl(Str content)
  {
    return content.contains("://") || 
           content.startsWith("http://") || 
           content.startsWith("https://") ||
           content.startsWith("ftp://") ||
           content.startsWith("mailto:")
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
** A link to an embedded video. Uses markdown image syntax.
** Supported uris for the video are:
** - Loom: ![Alt text](video://loom/<id>?sid=<sid>)
** - YouTube:
**   1. ![Alt text](video://youtu.be/<id>?si=<si>)
**   1. ![Alt text](video://youtube/<id>?si=<si>)
**
** You may specify additional query params and those will be applied as attributes
** to the rendered iframe in HTML
**
@Js
internal class Video : LinkNode
{
  new make(Str destination, Str alt) : super(destination, alt)
  {
    this.uri = destination.toUri
  }
  const Uri uri
  Str altText() { this.title ?: "Video" }
}

@Js
internal const class VideoProcessor : LinkProcessor
{
  new make() { }
  override LinkResult? process(LinkInfo info, Scanner scanner, InlineParserContext cx)
  {
    // ensure there is a link and this is not a link reference
    dest := info.destination
    if (dest == null) return null

    // check for image marker
    if (info.marker?.literal != "!") return null

    // check if it is a video:// uri
    uri := Uri.fromStr(dest, false)
    if (uri?.scheme != "video") return null

    return LinkResult.wrapTextIn(Video(dest, info.text), scanner.pos) { it.includeMarker = true }
  }
}

@Js
internal class VideoRenderer : NodeRenderer
{
  new make(HtmlContext cx)
  {
    this.cx = cx
    this.html = cx.writer
  }

  private HtmlContext cx
  private HtmlWriter html

  override const Type[] nodeTypes := [Video#]

  private static const [Str:Str?] stdAttrs := [
    "frameborder": "0",
    "allowfullscreen": null,
    "webkitallowfullscreen": null,
    "mozallowfullscreen": null,
    "width": "50%",
    "height": "35%",
  ]

  override Void render(Node node)
  {
    video := (Video)node
    type  := video.uri.host.lower
    switch (type)
    {
      case "loom": renderLoom(video)
      // case "vimeo": renderVimeo(embed)
      case "youtube":
      case "youtu.be":
        renderYoutube(video)
      default: throw UnsupportedErr("Video: '${type}'")
    }
  }

  private Void renderLoom(Video video)
  {
    uri := video.uri
    id  := uri.path.last.trimToNull ?: throw ParseErr("Invalid loom uri: ${uri}")
    sid := uri.query["sid"] ?: throw ParseErr("Invalid loom uri: ${uri}")
    src := `https://www.loom.com/embed/${id}?sid=${sid}`
    attrs := stdAttrs.dup.addAll([
      "title": "${video.altText}",
      "src": "${src}"
    ]).setAll(uri.query)
    renderVideo(attrs)
  }

  private Void renderYoutube(Video video)
  {
    uri := video.uri
    id  := uri.path.getSafe(0) ?: throw ParseErr("Invalid youtube uri: ${uri}")
    si  := uri.query["si"] ?: throw ParseErr("Invalid youtube uri: ${uri}")
    src := `https://www.youtube.com/embed/${id}?si=${si}`
    attrs := stdAttrs.dup.addAll([
      "title": "${video.altText}",
      "src":"${src}",
      "allow":"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; webshare",
      "referrerpolicy": "strict-origin-when-cross-origin",
    ]).setAll(uri.query)
    renderVideo(attrs)
  }

  private Void renderVideo([Str:Str?] attrs)
  {
    html.line
    html.tag("div", ["class": "xetodoc-video"])
    html.tag("iframe", attrs).tag("/iframe")
    html.tag("/div")
  }
}

**************************************************************************
** SpecLink
**************************************************************************

**
** A resolved spec reference link with semantic metadata
**
@Js
internal class SpecLink : Node
{
  new make(Str originalName, Str qname, Str specFlavor)
  {
    this.originalName = originalName
    this.qname = qname
    this.specFlavor = specFlavor
  }

  ** Original name that appeared in the markdown (e.g. "Str")
  const Str originalName

  ** Fully qualified name (e.g. "sys::Str")
  const Str qname

  ** Spec flavor (e.g. "type", "global", "func")
  const Str specFlavor
}

**************************************************************************
** BackticksSpecLinkParser
**************************************************************************

**
** Parses backticks containing resolved spec references in the format:
** `qname | SpecFlavor::flavor` and converts them to SpecLink nodes
**
@Js
internal class BackticksSpecLinkParser : InlineContentParser
{
  override ParsedInline? tryParse(InlineParserState state)
  {
    // parse with normal backticks semantics (only support single opener/closer sequence)
    res := BackticksInlineParser().withMaxMarkers(1).tryParse(state)
    if (res == null) return res

    // check if this is a resolved spec reference
    Code code := res.node
    content := code.literal
    
    // Look for the pattern: qname | SpecFlavor::flavor
    pipeIndex := content.index(" | ")
    if (pipeIndex == null) return null
    
    qname := content[0..<pipeIndex]
    remainder := content[pipeIndex+3..-1]
    
    // Check for SpecFlavor:: prefix
    if (!remainder.startsWith("SpecFlavor::")) return null
    
    specFlavor := remainder[12..-1]  // Remove "SpecFlavor::" prefix
    
    // Extract original name from qname (part after ::)
    colonIndex := qname.index("::")
    if (colonIndex == null) return null
    originalName := qname[colonIndex+2..-1]
    
    // Create SpecLink node
    specLink := SpecLink(originalName, qname, specFlavor)
    return ParsedInline.of(specLink, res.pos)
  }

  static const InlineContentParserFactory factory := BackticksSpecLinkParserFactory()
}

@Js
internal const class BackticksSpecLinkParserFactory : InlineContentParserFactory
{
  override const Int[] triggerChars := ['`']

  override InlineContentParser create() { BackticksSpecLinkParser() }
}

**************************************************************************
** SpecLinkRenderer
**************************************************************************

**
** Renders SpecLink nodes as div elements with qname and specFlavor attributes
**
@Js
internal class SpecLinkRenderer : NodeRenderer
{
  new make(HtmlContext cx)
  {
    this.cx = cx
    this.html = cx.writer
  }

  private HtmlContext cx
  private HtmlWriter html

  override const Type[] nodeTypes := [SpecLink#]

  override Void render(Node node)
  {
    specLink := (SpecLink)node
    
    attrs := [
      "class": "spec-link",
      "qname": specLink.qname,
      "specFlavor": specLink.specFlavor
    ]
    
    html.tag("div", attrs)
    html.text(specLink.originalName)
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
