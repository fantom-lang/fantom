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
    renderer.nodeRendererFactories.each |f| { nodeRendererMap.add(f(this)) }
  }

  private HtmlRenderer renderer
  private NodeRendererMap nodeRendererMap := NodeRendererMap()

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