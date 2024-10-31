//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

**
** A parsed link/image. There are different types of links.
**
** Inline links:
**   [text](destination)
**   [text](destination "title")
**
** Reference links, which have different subtypes. Full:
**   [text][label]
** Collapsed (label is ""):
**   [text][]
** Shorcut (label is null):
**   [text]
**
** Images use the same syntax as links but with a '!' marker front, e.g.
** '![text](destination)'.
**
@Js
mixin LinkInfo
{
  ** The marker if present, or null. A marker is e.g. '!' for an image, or
  ** a customer marker.
  abstract Text? marker()

  ** The text node of the opening bracket '['
  abstract Text openingBracket()

  ** The text between the first brackets, e.g. 'foo' in '[foo][bar]'
  abstract Str text()

  ** The label, or null for inline links or for shortcut links (in which case `text`
  ** should be used as the label).
  abstract Str? label()

  ** The destination if available, e.g. in '[foo](destination)', or null
  abstract Str? destination()

  ** The title if available, e.g. in '[foo](destination "title")', or null
  abstract Str? title()

  ** The position after the closing text bracket, e.g:
  ** pre>
  ** [foo][bar]
  **      ^
  ** <pre
  abstract Position afterTextBracket()
}

@Js
internal class MLinkInfo : LinkInfo
{
  new make(|This| f) { f(this) }

  override Text? marker { internal set }

  override Text openingBracket { internal set }

  override const Str text

  override const Str? label := null

  override const Str? destination := null

  override const Str? title := null

  override const Position afterTextBracket
}