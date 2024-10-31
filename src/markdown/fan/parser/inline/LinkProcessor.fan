//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** A mixin to decide how links/images are handled
**
** When inline parsing is run, each parsed link/image is passed to the processor.
** This includes links like these:
**
** pre>
** [text](destination)
** [text]
** [text][]
** [text][label]
** <pre
** And images
** pre>
** ![text](destination)
** ![text]
** ![text][]
** ![text][label]
** <pre
** See `LinkInfo` for accessing various parts of the parsed link/image
**
** The processor can then inspect the link/image and decide what to do with it by
** returning the appropriate `LinkResult`. If it returns null, the next registered
** processor is tried. If none of them apply, the link is handled as it normally would.
**
@Js
const mixin LinkProcessor
{
  ** 'info': information about the parsed link/image
  ** 'scanner': the scanner at the current position aftger the parsed link/image
  ** 'cx': context for inline parsing
  **
  ** Return what to do with the link/image, e.g. do nothing (try next processor),
  ** wrap the text in a node, or replace the link/image with a node.
  abstract LinkResult? process(LinkInfo info, Scanner scanner, InlineParserContext cx)
}

**************************************************************************
** CoreLinkProcessor
**************************************************************************

@Js
internal const class CoreLinkProcessor : LinkProcessor
{
  override LinkResult? process(LinkInfo info, Scanner scanner, InlineParserContext cx)
  {
    if (info.destination != null)
    {
      // inline link
      return doProcess(info, scanner, info.destination, info.title)
    }

    label := info.label
    ref := label != null && !label.isEmpty ? label : info.text
    def := cx.def(LinkReferenceDefinition#, ref) as LinkReferenceDefinition
    if (def != null)
    {
      // reference link
      return doProcess(info, scanner, def.destination, def.title)
    }
    return LinkResult.none
  }

  private static LinkResult doProcess(LinkInfo info, Scanner scanner, Str? dest, Str? title)
  {
    if (info.marker != null && info.marker.literal == "!")
    {
      // Image
      return LinkResult.wrapTextIn(Image(dest, title), scanner.pos) { it.includeMarker = true }
    }
    return LinkResult.wrapTextIn(Link(dest, title), scanner.pos)
  }
}

**************************************************************************
** LinkResult
**************************************************************************

@Js
class LinkResult
{
  ** Link not handled by processor
  static new none() { null }

  ** Wrap the link text in a node. This is the normal behavior for links, e.g. for this:
  ** pre>
  ** [my *text*](destination)
  ** <pre
  ** The text is 'my *text*', a text node and emphasis. The text is wrapped in a
  ** link node, which means the text is added as child nodes to it.
  **
  ** 'node': the node to which the link text nodes will be added as child nodes
  ** 'pos': the position to continue parsing from
  static new wrapTextIn(Node node, Position pos) { LinkResult(true, node, pos) }

  ** Replace the link with a node, e.g. for this:
  ** pre>
  ** [^foo]
  ** <pre
  ** The processor could decide to create a footnote reference node instead which
  ** replaces the link.
  **
  ** 'node': the node to replace the link with
  ** 'pos': the position to continue parsing from
  static new replaceWith(Node node, Position pos) { LinkResult(false, node, pos) }

  private new priv_make(Bool wrap, Node node, Position pos)
  {
    this.wrap = wrap
    this.node = node
    this.pos  = pos
  }

  const Bool wrap
  Bool replace() { !wrap }
  Node node { private set }
  const Position pos

  ** If a `LinkInfo.marker` is present, include it in processing
  ** (i.e. treat it the same way as the brackets).
  Bool includeMarker := false
}