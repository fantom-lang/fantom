//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2009  Andy Frank  Creation
//    8 Jul 2009  Andy Frank  Split webappClient into sys/dom
//    2 Jun 2011  Andy Frank  Rename to DomEvent
//   26 Aug 2015  Andy Frank  Rename back to Event
//

using graphics

**
** Event models the DOM event object.
**
** Common event types:
**
**   "mousedown"   Fired when a mouse button is pressed on an element.
**
**   "mouseup"     Fired when a mouse button is released over an element.
**
**   "click"       Fired when a mouse button is pressed and released on a
**                 single element.
**
**   "dblclick"    Fired when a mouse button is clicked twice on a single element.
**
**   "mousemove"   Fired when a mouse is moved while over an element.
**
**   "mouseover"   Fired when mouse is moved onto the element that has the
**                 listener attached or onto one of its children.
**
**   "mouseout"    Fired when mouse is moved off the element that has the
**                 listener attached or off one of its children.
**
**   "mouseenter"  Fired when mouse is moved over the element that has the
**                 listener attached. Similar to '"mouseover"', it differs in
**                 that it doesn't bubble and that it isn't sent when the mouse
**                 is moved from one of its descendants' physical space to its
**                 own physical space.
**
**                 With deep hierarchies, the amount of mouseenter events sent
**                 can be quite huge and cause significant performance problems.
**                 In such cases, it is better to listen for "mouseover" events.
**
**   "mouseleave"  Fired when mouse is moved off the element that has the
**                 listener attached. Similar to "mouseout", it differs in that
**                 it doesn't bubble and that it isn't sent until the pointer
**                 has moved from its physical space and the one of all its
**                 descendants.
**
**                 With deep hierarchies, the amount of mouseleave events sent
**                 can be quite huge and cause significant performance problems.
**                 In such cases, it is better to listen for "mouseout" events.
**
**   "contextmenu" Fired when the right button of the mouse is clicked (before
**                 the context menu is displayed), or when the context menu key
**                 is pressed (in which case the context menu is displayed at the
**                 bottom left of the focused element, unless the element is a
**                 tree, in which case the context menu is displayed at the
**                 bottom left of the current row).
**
**
**   "focus"       The focus event is fired when an element has received focus
**
**   "blur"        The blur event is fired when an element has lost focus.
**
**   "keydown"     Fired when a key is pressed down.
**
**   "keyup"       Fired when a key is released.
**
**   "keypress"    Fired when a key is pressed down and that key normally
**                 produces a character value (use "input" instead).
**
**   "input"       Fired synchronously when the value of an <input> or
**                 <textarea> element is changed.
**
**   "dragstart"   Fired on an element when a drag is started. The user is
**                 requesting to drag the element where the dragstart event is
**                 fired. During this event, a listener would set information
**                 such as the drag data and image to be associated with the drag.
**                 This event is not fired when dragging a file into the browser
**                 from the OS.
**
**   "dragenter"   Fired when the mouse enters an element while a drag is
**                 occurring. A listener for this event should indicate whether
**                 a drop is allowed over this location. If there are no listeners,
**                 or the listeners perform no operations, then a drop is not
**                 allowed by default. This is also the event to listen for in
**                 order to provide feedback that a drop is allowed, such as
**                 displaying a highlight or insertion marker.
**
**   "dragover"    This event is fired as the mouse is moving over an element
**                 when a drag is occurring. Much of the time, the operation that
**                 occurs during a listener will be the same as the "dragenter"
**                 event.
**
**   "dragleave"   This event is fired when the mouse leaves an element while a
**                 drag is occurring. Listeners should remove any highlighting
**                 or insertion markers used for drop feedback.
**
**   "drag"        This event is fired at the source of the drag and is the element
**                 where "dragstart" was fired during the drag operation.
**
**   "drop"        The drop event is fired on the element where the drop
**                 occurred at the end of the drag operation. A listener would
**                 be responsible for retrieving the data being dragged and
**                 inserting it at the drop location. This event will only fire
**                 if a drop is desired. It will not fire if the user cancelled
**                 the drag operation, for example by pressing the Escape key,
**                 or if the mouse button was released while the mouse was not
**                 over a valid drop target.
**
**   "dragend"     The source of the drag will receive a "dragend" event when the
**                 drag operation is complete, whether it was successful or not.
**                 This event is not fired when dragging a file into the browser
**                 from the OS.
**
@Js
class Event
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  private new make() {}

  ** Create a mock `Event` manullay.
  @NoDoc static native Event makeMock()

  ** Create an `Event` instance from a native JavaScript Event object.
  static native Event fromNative(Obj event)

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  ** The type of this event.
  native Str type()

  ** The target to which the event was dispatched.
  native Elem target()

  **
  ** Optional secondary target depending on event type:
  **
  **   event     target                relatedTarget
  **   --------  --------------------  -----------------------------
  **   blur      elem losing focus     elem receiving focus (if any)
  **   focus     elem receiving focus  elem losing focus (if any)
  **   focusin   elem receiving focus  elem losing focus (if any)
  **   focusout  elem losing focus     elem receiving focus (if any)
  **
  native Elem? relatedTarget()

  ** The mouse position of this event relative to page.
  native Point pagePos()

  ** Return true if the ALT key was pressed during the event.
  native Bool alt()

  ** Return true if the CTRL key was pressed during the event.
  native Bool ctrl()

  ** Return true if the SHIFT key was pressed during the event.
  native Bool shift()

  ** Return true if the Meta key was pressed during the event.  On Macs
  ** this maps to "command" key.  On Windows this maps to "Windows" key.
  native Bool meta()

  ** Mouse button number pressed.
  native Int? button()

  ** Scroll amount for wheel events.
  native Point? delta()

  ** Key instance for key pressed.
  native Key? key()

  ** Err instance if available for 'window.onerror'.
  native Err? err()

  ** Stop further propagation of this event.
  native Void stop()

  ** Get an attribute by name.  If not found return
  ** the specified default value.
  @Operator native Obj? get(Str name, Obj? def := null)

  ** Set an attribute to the given value.
  @Operator native Void set(Str name, Obj? val)

  ** Get or set an attribute.
  override Obj? trap(Str name, Obj?[]? args := null)
  {
    if (args == null || args.isEmpty) return get(name)
    set(name, args.first)
    return null
  }

  ** The DataTransfer object for this event.
  native DataTransfer dataTransfer()

  ** Meta-data for this event instance.
  Str:Obj? stash := Str:Obj?[:]

  override Str toStr()
  {
    "Event { type=$type target=$target pagePos=$pagePos button=$button delta=$delta key=$key" +
    " alt="   + (alt   ? "T" : "F") +
    " ctrl="  + (ctrl  ? "T" : "F") +
    " shift=" + (shift ? "T" : "F") +
    " meta="  + (meta  ? "T" : "F") +
    " }"
  }
}