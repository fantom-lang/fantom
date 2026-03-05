//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

using util


**
** The xetodoc class contains several utilities for configuring and rendering
** xetodoc markdown.
**
** pre>
** Configure Xetodoc with custom link reseolver and warning handler
** xetodoc := Xetodoc
**   .withLinkResolver(MyLinkResolver())
**   .onWarn |node, msg| { echo("${node.loc}: ${msg}") }
** <pre
**
@Js
@NoDoc
class Xetodoc
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(|This|? f := null)
  {
    f?.call(this)
  }

  private static const MarkdownExt[] exts := [XetodocExt()]

  ** The link resolver to use
  LinkResolver? linkResolver { protected set }

  ** Configure a link resolver and return this
  This withLinkResolver(LinkResolver? linkResolver)
  {
    this.linkResolver = linkResolver
    return this
  }

  ** Callback to handle warnings on nodes.
  |Node node, Str msg|? onWarnCb { protected set }

  ** Configure the callback for warnings. The node and a warning message are passed.
  ** The location of the warning can be obtained from the node by using `Node.loc` or
  ** inspecting the `Node.sourceSpans`. Currently warnings are only generated when
  ** block or inline HTML nodes are found in the xetdoc source.
  This onWarn(|Node node, Str msg| cb) { this.onWarnCb = cb; return this }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  ** Parse Xetodoc source into a `Document`
  Document parse(Str source) { parser.parse(source) }

  ** Get a fully-configured Xetodoc parser. Note that if the parser is re-used, and
  ** you configured a `LinkResolver`, then the link resolver should be idempotent.
  Parser parser()
  {
    builder := parserBuilder
    if (linkResolver != null)
      builder.postProcessorFactory |->LinkResolver| { linkResolver }
    if (onWarnCb != null)
      builder.postProcessorFactory |->WarnProcessor| { WarnProcessor(onWarnCb) }
    return builder.build
  }

  ** Get a `ParserBuilder` with all the standard Xetodoc features enabled.
  ParserBuilder parserBuilder()
  {
    Parser.builder
      .withIncludeSourceSpans(IncludeSourceSpans.blocks_and_inlines)
      .linkProcessor(VideoProcessor())
      .linkProcessor(BracketLinkProcessor())
      .extensions(exts)
  }

//////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////

  ** Convenience to render the given Xetodoc source to HTML
  Str toHtml(Str source)
  {
    htmlRenderer.render(parser.parse(source))
  }

  ** Get a Xetotodc html renderer
  HtmlRenderer htmlRenderer() { htmlBuilder.build }

  ** Get an `HtmlRendererBuilder` with all the standard Xetodoc features enabled.
  HtmlRendererBuilder htmlBuilder()
  {
    HtmlRenderer.builder
      .withDisableHtml
      .nodeRendererFactory |cx->NodeRenderer| { VideoRenderer(cx) }
      .extensions(exts)
  }

  // ** Convenience to render the given node to HTML
  // static Str renderToHtml(Node node) { htmlRenderer.render(node) }

  // ** Convenience to render parsed AST back to Xetodoc markdown text
  // Str renderToMarkdown(Node node) { markdownRenderer.render(node) }

  // ** Get a Xetodoc markdown renderer
  // static const MarkdownRenderer markdownRenderer := markdownBuilder.build

  // ** Get a `MarkdownRendererBuilder` with all the standard Xetodoc features enabled.
  // static MarkdownRendererBuilder markdownBuilder()
  // {
  //   MarkdownRenderer.builder.extensions(xetodoc)
  // }
}

**************************************************************************
** WarnProcessor
**************************************************************************

@Js
internal class WarnProcessor : PostProcessor, Visitor
{
  new make(|Node, Str| cb) { this.cb = cb }

  private |Node, Str| cb

  override Node process(Node node)
  {
    node.walk(this)
    return node
  }

  override Void visitHtmlBlock(HtmlBlock block)
  {
    cb(block, "Block HTML is ignored")
  }

  override Void visitHtmlInline(HtmlInline inline)
  {
    cb(inline, "Inline HTML is ignored")
  }

}

**
** Xetodoc is a curated set of features and extensions to the CommonMark syntax.
**
** - Disables rendering of inline and block HTML nodes
** - Adds syntactic sugar for [foo] to be parsed as [foo](foo)
** - Enables the following extensions: `ImgAttrsExt`, and `TablesExt`
** - Enables embedding videos in HTML using image links using video scheme links
**   - ![alt text](video://youtu.be/abc?si=123)
**   - ![alt text](video://loom/def?sid=456)
**
** The `Xetodoc` class is the recommended way to configure and render Xetodoc source.
**
** pre>
** // Configure xetodoc with a custom link resolver
** xetodoc  := Xetodoc().withLinkResolver(MyCustomLinkResolver())
**
** // Obtain explicit parser and renderer to generate HTML
** parser   := xetodoc.parser
** renderer := Xetodoc.htmlRenderer
** html := renderer.render(parser.parse("Hello `Xetodoc`!"))
**
** // Generate HTML using convenience method
** html = xetodoc.toHtml("Hello, `Xetodoc`!")
** <pre
**
@Js
@NoDoc internal const class XetodocExt : MarkdownExt
{

//////////////////////////////////////////////////////////////////////////
// MarkdownExt
//////////////////////////////////////////////////////////////////////////

  ** Extensions automatically enabled by the Xetodoc extension
  private static const MarkdownExt[] exts := [ImgAttrsExt(), TablesExt()]

  override Void extendParser(ParserBuilder builder)
  {
    builder
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
    builder.extensions(exts)
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
** BracketsLink
**************************************************************************

@Js
internal const class BracketLinkProcessor : CoreLinkProcessor
{
  override LinkResult? process(LinkInfo info, Scanner scanner, InlineParserContext cx)
  {
    // try normal processing - if it succeeds it takes precedence
    res := super.process(info, scanner, cx)
    if (res != null) return res

    // treat shortcut [foo] as a [foo](foo). The normal CoreLinkProcessor
    // would just leave it as Text node if it doesn't resolve to a link reference.
    // Also - dont't allow empty brackets (e.g. Str[])
    if (info.label == null && !info.text.isEmpty)
    {
      link := Link(info.text)
      link.shortcut = true
      return LinkResult.wrapTextIn(link, scanner.pos)
    }
    return LinkResult.none
  }
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

  private static const [Str:Str] stdAttrs := [
    "frameborder": "0",
    "allowfullscreen": "true",
    "width": "960",
    "height": "540",
  ]

  override Void render(Node node)
  {
    video := (Video)node
    type  := video.uri.host.lower
    switch (type)
    {
      case "loom":
        renderLoom(video)
      case "vimeo":
        renderVimeo(video)
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

  private Void renderVimeo(Video video)
  {
    uri := video.uri
    path := uri.toStr
    if (!path.startsWith("video://vimeo/")) echo("WARN: invalid vimeo URI: $uri")
    else path = path["video://vimeo/".size..-1]
    src := `https://player.vimeo.com/video/${path}`
    attrs := stdAttrs.dup.addAll([
      "title": "${video.altText}",
      "portrait": "0",
      "byline":"0",
      "src": src.toStr,
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

