//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

**
** PostProcessors are run as the last step of parsing and provide an opportunity
** to inspect/modify the parsed AST before rendering.
**
@Js
mixin PostProcessor
{
  ** Post-process this node and return the result (which may be a modified node).
  abstract Node process(Node node)
}

**
** A post-processor handling link resolution
**
@Js
@NoDoc mixin LinkResolver : PostProcessor, Visitor
{
  override Node process(Node node)
  {
    node.walk(this)
    return node
  }

  override Void visitLink(Link link) { resolve(link) }
  override Void visitImage(Image img) { resolve(img) }

  ** Resolve the given `LinkNode`. This will be called prior to any rendering
  ** for the given node and provides an opportunity to modify the link destination,
  ** mark the link as code, and change the link display text.
  protected abstract Void resolve(LinkNode linkNode)
}
