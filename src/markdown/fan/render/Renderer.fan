//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

**
** Renders a tree of nodes
**
@Js
mixin Renderer
{
  abstract Void renderTo(OutStream out, Node node)

  virtual Str render(Node node)
  {
    sb := StrBuf()
    renderTo(sb.out, node)
    return sb.toStr
  }
}

**************************************************************************
** NodeRenderer
**************************************************************************

**
** A renderer for a set of node types
**
@Js
mixin NodeRenderer
{
  ** Get the `Node` types that this renderer handles.
  abstract Type[] nodeTypes()

  ** Render the specified node
  abstract Void render(Node node)

  ** Called before the root node is rendered, to do any initial processing at the start
  virtual Void beforeRoot(Node rootNode) { }

  ** Called after the root node is rendered, to do any final processing at the end
  virtual Void afterRoot(Node rootNode) { }
}

**************************************************************************
** NodeRendererMap
**************************************************************************

@Js
internal class NodeRendererMap
{
  new make()
  {
    this.renderers = [:] { it.ordered = true }
  }

  private [Type:NodeRenderer] renderers

  Void add(NodeRenderer renderer)
  {
    renderer.nodeTypes.each |type|
    {
      // ensure type is a Node#
      if (!type.fits(Node#)) throw ArgErr("${type} is not a ${Node#}")

      // the first node renderer for a node type "wins"
      if (!renderers.containsKey(type)) renderers[type] = renderer
    }
  }

  Void render(Node node)
  {
    renderers[node.typeof]?.render(node)
  }

  Void beforeRoot(Node node) { renderers.vals.each { it.beforeRoot(node) } }
  Void afterRoot(Node node) { renderers.vals.each { it.afterRoot(node) } }
}