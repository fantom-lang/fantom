//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

**
** Renders a tree of nodes to plain text
**
@Js
const class TextRenderer : Renderer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Obtain a builder for configuring the renderer
  static TextRendererBuilder builder() { TextRendererBuilder() }

  ** Get a renderer with all the default configuration
  static new make() { builder.build }

  internal new makeBuilder(TextRendererBuilder builder)
  {
    this.lineBreakRendering = builder.lineBreakRendering

    factories := builder.nodeRendererFactories
    factories.add(|cx->NodeRenderer| { CoreTextNodeRenderer(cx) })
    this.nodeRendererFactories = factories
  }

  internal const LineBreakRendering lineBreakRendering
  internal const |TextContext->NodeRenderer|[] nodeRendererFactories

//////////////////////////////////////////////////////////////////////////
// Render
//////////////////////////////////////////////////////////////////////////

  override Void renderTo(OutStream out, Node node)
  {
    cx := TextContext(this, TextWriter(out, this.lineBreakRendering))
    cx.render(node)
  }
}

**************************************************************************
** TextRendererBuilder
**************************************************************************

**
** Builder for configuring a `TextRenderer`
**
@Js
final class TextRendererBuilder
{
  internal new make() { }

  internal |TextContext->NodeRenderer|[] nodeRendererFactories := [,]
  internal LineBreakRendering lineBreakRendering := LineBreakRendering.compact

  ** Get the configured `TextRenderer`
  TextRenderer build() { TextRenderer(this) }

  ** Configure how line breaks (newlines) are rendered. The default is
  ** `LineBreakRendering.compact`
  This withLineBreakRendering(LineBreakRendering lineBreakRendering)
  {
    this.lineBreakRendering = lineBreakRendering
    return this
  }

  ** Add a factory for instantiating a node renderer (done when rendering). This allows
  ** This allows to override the rendering of node types or define rendering for
  ** custom node types.
  **
  ** If multiple node renderers for the same node type are created, the one from the
  ** factory that was added first "wins". (This is how the rendering for core node types
  ** can be overridden; the default rendering comes last).
  This nodeRendererFactory(|TextContext->NodeRenderer| factory)
  {
    nodeRendererFactories.add(factory)
    return this
  }

  ** Enable the given extensions on this renderer.
  This extensions(MarkdownExt[] exts)
  {
    exts.each |ext| { ext.extendText(this) }
    return this
  }
}

**************************************************************************
** LineBreakRendering
**************************************************************************

@Js
enum class LineBreakRendering
{
  ** Strip all line breaks within blocks and between blocks, resulting in all the
  ** text on a single line.
  strip,
  ** Use single line breaks between blocks, not a blank line.
  ** Also renderes all lists as tight
  compact,
  ** Separate blocks by a blank line (and respect tight vs loose lists)
  separate_blocks
}
