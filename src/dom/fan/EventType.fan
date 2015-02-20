//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Feb 2015  Andy Frank  Creation
//

**
** EventType contains constants for the different DOM event types,
** which are used in methods like `Elem.onEvent`.
**
@Js const class EventType
{
  ** Fired when a mouse button is pressed on an element.
  static const Str mouseDown := "mousedown"

  ** Fired when a mouse button is released over an element.
  static const Str mouseUp := "mouseup"

  ** Fired when a mouse button is pressed and released on a single element.
  static const Str mouseClick := "click"

  ** Fired when a mouse button is clicked twice on a single element.
  static const Str mouseDoubleClick := "dblclick"

  ** Fired when a mouse is moved while over an element.
  static const Str mouseMove := "mousemove"

  ** Fired when mouse is moved onto the element that has the
  ** listener attached or onto one of its children.
  static const Str mouseOver := "mouseover"

  ** Fired when mouse is moved off the element that has the
  ** listener attached or off one of its children.
  static const Str mouseOut := "mouseout"

  **
  ** Fired when mouse is moved over the element that has the listener
  ** attached.  Similar to `mouseOver`, it differs in that it doesn't
  ** bubble and that it isn't sent when the mouse is moved from one of
  ** its descendants' physical space to its own physical space.
  **
  ** With deep hierarchies, the amount of mouseenter events sent can be
  ** quite huge and cause significant performance problems. In such cases,
  ** it is better to listen for `mouseOver` events.
  **
  static const Str mouseEnter := "mouseenter"

  **
  ** Fired when mouse is moved off the element that has the listener
  ** attached. Similar to `mouseOut`, it differs in that it doesn't bubble
  ** and that it isn't sent until the pointer has moved from its physical
  ** space and the one of all its descendants.
  **
  ** With deep hierarchies, the amount of mouseleave events sent can be
  ** quite huge and cause significant performance problems. In such cases,
  ** it is better to listen for `mouseOut` events.
  **
  static const Str mouseLeave := "mouseleave"

  **
  ** Fired when the right button of the mouse is clicked (before the context
  ** menu is displayed), or when the context menu key is pressed (in which
  ** case the context menu is displayed at the bottom left of the focused
  ** element, unless the element is a tree, in which case the context menu
  ** is displayed at the bottom left of the current row).
  **
  static const Str contextMenu := "contextmenu"

  ** Fired when a key is pressed down.
  static const Str keyDown := "keydown"

  ** Fired when a key is released.
  static const Str keyUp := "keyup"

  ** Fired when a key is pressed down and that key normally
  ** produces a character value (use input instead).
  static const Str keyPress := "keypress"

  ** Fired synchronously when the value of an '<input>' or
  ** '<textarea>' element is changed.
  static const Str input := "input"
}