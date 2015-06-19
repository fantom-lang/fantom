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

  **
  ** Fired on an element when a drag is started. The user is requesting to
  ** drag the element where the dragstart event is fired. During this event,
  ** a listener would set information such as the drag data and image to be
  ** associated with the drag. This event is not fired when dragging a file
  ** into the browser from the OS.
  **
  static const Str dragStart := "dragstart"

  **
  ** Fired when the mouse enters an element while a drag is occurring. A
  ** listener for this event should indicate whether a drop is allowed over
  ** this location. If there are no listeners, or the listeners perform no
  ** operations, then a drop is not allowed by default. This is also the event
  ** to listen for in order to provide feedback that a drop is allowed, such
  ** as displaying a highlight or insertion marker.
  **
  static const Str dragEnter := "dragenter"

  **
  ** This event is fired as the mouse is moving over an element when a drag
  ** is occurring. Much of the time, the operation that occurs during a
  ** listener will be the same as the `dragEnter` event.
  **
  static const Str dragOver := "dragover"

  **
  ** This event is fired when the mouse leaves an element while a drag is
  ** occurring. Listeners should remove any highlighting or insertion markers
  ** used for drop feedback.
  **
  static const Str dragLeave := "dragleave"

  **
  ** This event is fired at the source of the drag and is the element where
  ** `dragStart` was fired during the drag operation.
  **
  static const Str drag := "drag"

  **
  ** The drop event is fired on the element where the drop occurred at
  ** the end of the drag operation. A listener would be responsible for
  ** retrieving the data being dragged and inserting it at the drop location.
  ** This event will only fire if a drop is desired. It will not fire if the
  ** user cancelled the drag operation, for example by pressing the Escape
  ** key, or if the mouse button was released while the mouse was not over a
  ** valid drop target.
  **
  static const Str drop := "drop"

  **
  ** The source of the drag will receive a 'dragEnd' event when the drag
  ** operation is complete, whether it was successful or not. This event is
  ** not fired when dragging a file into the browser from the OS.
  **
  static const Str dragEnd := "dragend"
}