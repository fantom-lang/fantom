//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

**
** Renders a tree of nodes to HTML
**
@Js
const class HtmlRenderer : Renderer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Obtain a builder for configuring the renderer
  static HtmlRendererBuilder builder() { HtmlRendererBuilder() }

  ** Get a renderer with all the default configuration
  static new make() { builder.build }

  internal new makeBuilder(HtmlRendererBuilder builder)
  {
    this.softbreak = builder.softbreak
    this.escapeHtml = builder.escapeHtml
    this.percentEncodeUrls = builder.percentEncodeUrls
    this.omitSingleParagraphP = builder.omitSingleParagraphP
    this.sanitizeUrls = builder.sanitizeUrls
    this.attrProviderFactories = builder.attrProviderFactories

    factories := builder.nodeRendererFactories.dup
    factories.add(|cx->NodeRenderer| { CoreHtmlNodeRenderer(cx) })
    this.nodeRendererFactories = factories
  }

  internal const Str softbreak
  internal const Bool escapeHtml
  internal const Bool percentEncodeUrls
  internal const Bool omitSingleParagraphP
  internal const Bool sanitizeUrls
  internal const |HtmlContext->NodeRenderer|[] nodeRendererFactories
  internal const |HtmlContext->AttrProvider|[] attrProviderFactories
  internal const UrlSanitizer urlSanitizer := DefaultUrlSanitizer()

//////////////////////////////////////////////////////////////////////////
// Render
//////////////////////////////////////////////////////////////////////////

  override Void renderTo(OutStream out, Node node)
  {
    cx := HtmlContext(this, HtmlWriter(out))
    cx.beforeRoot(node)
    cx.render(node)
    cx.afterRoot(node)
  }
}

**************************************************************************
** HtmlRendererBuilder
**************************************************************************

**
** Builder for configuring an `HtmlRenderer`.
**
@Js
final class HtmlRendererBuilder
{
  internal new make() { }

  internal |HtmlContext->NodeRenderer|[] nodeRendererFactories := [,]
  internal |HtmlContext->AttrProvider|[] attrProviderFactories := [,]
  internal Str softbreak := "\n"
  internal Bool escapeHtml := false
  internal Bool percentEncodeUrls := false
  internal Bool omitSingleParagraphP := false
  internal Bool sanitizeUrls := false

  ** Get the configured `HtmlRenderer`
  HtmlRenderer build() { HtmlRenderer(this) }

  ** The HTML to use for rendering a softbreak, default to '\n' (meaning the
  ** rendered result doesn't have a line break).
  **
  ** Set it to '<br>' or '<br />' to make the hard breaks.
  **
  ** Set it to ' ' (space) to ingore line wrapping in the source.
  This withSoftBreak(Str s)
  {
    this.softbreak = s
    return this
  }

  ** Whether `HtmlInline` and `HtmlBlock` should be escaped, defaults to 'false'.
  **
  ** Note that `HtmlInline` is only a tag itself, not the text between an opening tag
  ** and closing tag. So markup in the text will be parsed as normal and is not affected
  ** by this option.
  This withEscapeHtml(Bool val := true)
  {
    this.escapeHtml = val
    return this
  }

  ** Whether URLs of link or images should be percent-encoded, defaults to 'false'.
  **
  ** If enabled, the following is done:
  ** - Existing percent-encoded parts are preserved (e.g. "%20" is kept as "%20")
  ** - Reserved characters such as "/" are preserved, except for "[" and "]"
  **   (see encodeURL in JS).
  ** - Other characters such as umlauts are percent-encoded
  This withPercentEncodeUrls(Bool val := true)
  {
    this.percentEncodeUrls = val
    return this
  }

  ** Whether documents that only contain a single paragraph shoudl be rendered without
  ** the '<p>' tag. Set to 'true' to render without the tag; the default of 'false'
  ** always renders the tag.
  This withOmitSingleParagraphP(Bool val := true)
  {
    this.omitSingleParagraphP = val
    return this
  }

  ** Whether `Image` src and `Link` href should be sanitized, defaults to 'false'.
  This withSanitizeUrls(Bool val := true)
  {
    this.sanitizeUrls = val
    return this
  }

  ** Add a factory for instantiating a node renderer (done when rendering). This allows
  ** to override the rendering of node types or define rendering for custom node types.
  **
  ** If multiple node renderers for the same node type are created, the one from the
  ** factory that was added first "wins". (This is how rendering for core node types
  ** can be overriden; the default rendering comes last).
  This nodeRendererFactory(|HtmlContext->NodeRenderer| factory)
  {
    nodeRendererFactories.add(factory)
    return this
  }

  ** Add a factory for an attribute provider for adding/changing HTML attributes to the
  ** rendered tags.
  This attrProviderFactory(|HtmlContext->AttrProvider| factory)
  {
    attrProviderFactories.add(factory)
    return this
  }

  ** Configure the given extensions on this this renderer
  This extensions(MarkdownExt[] exts)
  {
    exts.each |ext| { ext.extendRenderer(this) }
    return this
  }

}
