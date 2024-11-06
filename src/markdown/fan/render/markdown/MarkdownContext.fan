//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

**
** Context for rendering nodes to Markdown
**
@Js
class MarkdownContext
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  internal new make(MarkdownRenderer renderer, MarkdownWriter writer)
  {
    this.renderer = renderer
    this.writer = writer

    // the first node renderer for a node type "wins"
    renderer.nodeRendererFactories.each |f| { nodeRendererMap.add(f(this)) }
  }

  private MarkdownRenderer renderer
  private NodeRendererMap nodeRendererMap := NodeRendererMap()

//////////////////////////////////////////////////////////////////////////
// MarkdownContext
//////////////////////////////////////////////////////////////////////////

  MarkdownWriter writer { private set }

  Int[] specialChars() { renderer.specialChars }

  Void render(Node node) { nodeRendererMap.render(node) }

  internal Void beforeRoot(Node node)
  {
    nodeRendererMap.beforeRoot(node)
  }

  internal Void afterRoot(Node node)
  {
    nodeRendererMap.afterRoot(node)
  }
}