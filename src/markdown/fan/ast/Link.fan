//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

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
class Link : Node
{
  new make(Str destination, Str? title := null)
  {
    this.destination = destination
    this.title = title
  }

  Str destination
  Str? title

  override protected Str toStrAttributes() { "dest=${destination}, title=${title}" }
}

**************************************************************************
** Image
**************************************************************************

** Image node
@Js
class Image : Node
{
  new make(Str destination, Str? title := null)
  {
    this.destination = destination
    this.title = title
  }

  Str destination
  Str? title

  override protected Str toStrAttributes() { "dest=${destination}, title=${title}" }
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