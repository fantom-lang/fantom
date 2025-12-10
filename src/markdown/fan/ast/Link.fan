//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Base class for `Link` and `Image` nodes
**
@Js
abstract class LinkNode : Node
{
  new make(Str destination, Str? title := null)
  {
    this.destination = destination
    this.title = title
  }

  ** Link URL destination
  Str destination

  ** Optional link title
  Str? title

  ** Should the link be treated as inline code
  @NoDoc Bool isCode := false

  ** Replace the display text for this link
  @NoDoc Void setText(Str text) { setContent(Text(text)) }
  ** Replace the display content with the given node
  @NoDoc Void setContent(Node content)
  {
    children.each |child| { child.unlink }
    appendChild(content)
  }

  override protected Str toStrAttributes() { "dest=${destination}, title=${title}" }
}

**
** A link with a destination and an optional title; the link text is in child nodes
**
** Example for an inline link in a CommonMark document
**
** pre>
** [link](/uri "title")
** <pre
**
** Note that the text in the link can contain inline formatting, so it could also
** contain an image or emphasis, etc.
**
@Js
class Link : LinkNode
{
  new make(Str destination, Str? title := null) : super(destination, title)
  {
  }
}

**************************************************************************
** Image
**************************************************************************

** An image
** pre>
** ![foo](/url "title")
** <pre
**
** The corresponding `LinkNode` would look like this:
** - 'destination' => '/uri'
** - 'title' => "title"
** - A `Text` child node with 'literal' that returns "link"
**
** Note that the text in the link can contain inline formatting, so it could
** also contain an `Image` or `Emphasis`, etc.
@Js
class Image : LinkNode
{
  new make(Str destination, Str? title := null) : super(destination, title)
  {
  }
}

**************************************************************************
** LinkReferenceDefinition
**************************************************************************

**
** A link reference definition
**
** pre>
** [foo]: /url "title"
** <pre
**
** They can be referenced anywhere else in the document to produce a link using
** '[foo]'. The definitions themselves are usually not rendered in the final output.
**
@Js
class LinkReferenceDefinition : Block
{
  new make(Str label, Str destination, Str? title)
  {
    this.label = label
    this.destination = destination
    this.title = title
  }

  const Str label
  const Str destination
  const Str? title
}