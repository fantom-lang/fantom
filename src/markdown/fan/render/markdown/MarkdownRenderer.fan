//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

**
** Renders nodes to Markdown (CommonMark syntax).
**
@Js
const class MarkdownRenderer : Renderer
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Obtain a builder for configuring the renderer
  static MarkdownRendererBuilder builder() { MarkdownRendererBuilder() }

  ** Get a renderer with all the default configuration
  static new make() { builder.build }

  internal new makeBuilder(MarkdownRendererBuilder builder)
  {
    this.specialChars = builder.specialChars

    factories := builder.nodeRendererFactories.dup
    factories.add(|cx->NodeRenderer| { CoreMarkdownNodeRenderer(cx) })
    this.nodeRendererFactories = factories
  }

  internal const |MarkdownContext->NodeRenderer|[] nodeRendererFactories
  internal const Int[] specialChars

//////////////////////////////////////////////////////////////////////////
// Render
//////////////////////////////////////////////////////////////////////////

  override Void renderTo(OutStream out, Node node)
  {
    cx := MarkdownContext(this, MarkdownWriter(out))
    cx.beforeRoot(node)
    cx.render(node)
    cx.afterRoot(node)
  }
}

**************************************************************************
** MarkdownRendererBuilder
**************************************************************************

**
** Builder for configuring a `MarkdownRenderer`
**
@Js
final class MarkdownRendererBuilder
{
  internal new make() { }

  internal |MarkdownContext->NodeRenderer|[] nodeRendererFactories := [,]
  internal |MarkdownContext, Node|[] nodePostProcessors := [,]
  internal Int[] specialChars := [,]

  ** Build the configured `MarkdownRenderer`.
  MarkdownRenderer build() { MarkdownRenderer(this) }

  ** Add a factory for a node renderer. This allows to override the rendering of
  ** node types or define rendering for custom node types.
  This nodeRendererFactory(|MarkdownContext->NodeRenderer| factory)
  {
    this.nodeRendererFactories.add(factory)
    return this
  }

  ** Register additional special characters that must be escaped in normal text
  This withSpecialChars(Int[] special)
  {
    this.specialChars.addAll(special)
    return this
  }

  ** Enable the given extensions on this renderer.
  This extensions(MarkdownExt[] exts)
  {
    exts.each |ext| { ext.extendMarkdown(this) }
    return this
  }
}