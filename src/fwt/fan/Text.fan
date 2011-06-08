//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 08  Brian Frank  Creation
//

**
** Text is used to enter and modify text.
**
@Js
@Serializable
class Text : TextWidget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Callback when Return/Enter key is pressed in a single
  ** line text editor (not invoked for multiLine)
  **
  ** Event id fired:
  **   - `EventId.action`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onAction() { EventListeners() }

  **
  ** Callback when the text is modified.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onModify() { EventListeners() }

  **
  ** True to make this a password text field which hides the
  ** characters being typed.  Default is false.  This field
  ** cannot be changed once the widget is constructed.
  **
  const Bool password := false

  **
  ** The current text. Defaults to "".
  **
  override native Str text

  **
  ** Replace the text with 'newText' starting at position 'start'
  ** for a length of 'replaceLen'.
  **
  override Void modify(Int start, Int replaceLen, Str newText)
  {
    text = text[0..<start] + newText + text[start+replaceLen..-1]
  }

}