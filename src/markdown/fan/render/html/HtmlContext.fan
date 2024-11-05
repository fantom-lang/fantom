//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Context for rendering nodes to HTML
**
@Js
class HtmlContext
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  internal new make(HtmlRenderer renderer, HtmlWriter writer)
  {
    this.renderer = renderer
    this.writer = writer
    renderer.attrProviderFactories.each |f| { attrProviders.add(f(this)) }
    renderer.nodeRendererFactories.each |f| { nodeRendererMap.add(f(this)) }
  }

  private HtmlRenderer renderer
  private NodeRendererMap nodeRendererMap := NodeRendererMap()
  private AttrProvider[] attrProviders := [,]

//////////////////////////////////////////////////////////////////////////
// HtmlContext
//////////////////////////////////////////////////////////////////////////

  HtmlWriter writer { private set }

  Bool escapeHtml() { renderer.escapeHtml}

  Bool sanitizeUrls() { renderer.sanitizeUrls }

  Bool omitSingleParagraphP() { renderer.omitSingleParagraphP }

  Bool percentEncodeUrls() { renderer.percentEncodeUrls }

  Str softbreak() { renderer.softbreak }

  Str encodeUrl(Str url)
  {
    percentEncodeUrls ? Esc.percentEncodeUrl(url) : url
  }

  UrlSanitizer urlSanitizer() { renderer.urlSanitizer }

  [Str:Str?] extendAttrs(Node node, Str tagName, [Str:Str?] attrs := [:])
  {
    // ensure attributes are ordered from this point forward
    attrs = [Str:Str?][:] { ordered = true }.addAll(attrs)
    attrProviders.each |provider| { provider.setAttrs(node, tagName, attrs) }
    return attrs
  }

  Void render(Node node)
  {
    nodeRendererMap.render(node)
  }

//////////////////////////////////////////////////////////////////////////
// Internal
//////////////////////////////////////////////////////////////////////////

  internal Void beforeRoot(Node node)
  {
    nodeRendererMap.beforeRoot(node)
  }

  internal Void afterRoot(Node node)
  {
    nodeRendererMap.afterRoot(node)
  }

}

**************************************************************************
** AttrProvider
**************************************************************************

**
** Extension point for adding/changing attributes on HTML tags for a node.
**
@Js
mixin AttrProvider
{
  **
  ** Set the attributes for an HTML tag of the specified node by modyfing the provided map.
  **
  ** This allows to change or even remove default attributes.
  **
  ** The attribute key and values will be escaped (preserving character entities), so
  ** don't escape them here, otherwise they will be double-escaped.
  **
  ** This method may be called multiple times for the same node, if the node is rendered
  ** using multiple nested tags (e.g. code blocks)
  abstract Void setAttrs(Node node, Str tagName, [Str:Str?] attrs)
}