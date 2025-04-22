//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

**
** Context for rendering nodes to plain text
**
@Js
class TextContext
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  internal new make(TextRenderer renderer, TextWriter writer)
  {
    this.renderer = renderer
    this.writer   = writer
    renderer.nodeRendererFactories.each |f| { nodeRendererMap.add(f(this)) }
  }

  private TextRenderer renderer
  private NodeRendererMap nodeRendererMap := NodeRendererMap()

//////////////////////////////////////////////////////////////////////////
// TextContext
//////////////////////////////////////////////////////////////////////////

  TextWriter writer { private set }

  Bool stripNewLines() { renderer.lineBreakRendering === LineBreakRendering.strip }

  Void render(Node node)
  {
    nodeRendererMap.render(node)
  }

}