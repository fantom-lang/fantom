//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using gfx

//
// TODO:
// Widgets:
//   - ScrollPane
// Eventing
//   - focus management
// Graphics:
//   - affine transformations
//

**
** Widget is the base class for all UI widgets.
**
** See [pod doc]`pod-doc#widgets` for details.
**
@Js
abstract class Widget
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Internal constructor: subclass `Canvas` or `Pane`.
  **
  internal new make() {}

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Enabled is used to control whether this widget can
  ** accept user input.  Disabled controls are "grayed out".
  **
  native Bool enabled

  **
  ** Controls whether this widget is visible or hidden.
  **
  native Bool visible

  **
  ** Mouse cursor to use when the mouse passes over the control.
  ** If not specified cursor of the parent control will appear.
  **
  native Cursor? cursor

  **
  ** Meta-data that can be used by `Pane` for layout.
  **
  Obj? layout := null

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  **
  ** Callback for key pressed event on this widget.  To cease propagation
  ** and processing of the event, then [consume]`Event.consume` it.
  **
  ** Event id fired:
  **   - `EventId.keyDown`
  **
  ** Event fields:
  **   - `Event.keyChar`: unicode character represented by key event
  **   - `Event.key`: key code including the modifiers
  **
  once EventListeners onKeyDown()
  {
    EventListeners() { onModify = |->| { checkKeyListeners } }
  }

  internal native Void checkKeyListeners()

  **
  ** Callback for key released events on this widget.  To cease propagation
  ** and processing of the event, then [consume]`Event.consume` it.
  **
  ** Event id fired:
  **   - `EventId.keyUp`
  **
  ** Event fields:
  **   - `Event.keyChar`: unicode character represented by key event
  **   - `Event.key`: key code including the modifiers
  **
  once EventListeners onKeyUp()
  {
    EventListeners() { onModify = |->| { checkKeyListeners } }
  }

  **
  ** Callback for mouse button pressed event on this widget.
  **
  ** Event id fired:
  **   - `EventId.mouseDown`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **   - `Event.count`: number of clicks
  **   - `Event.key`: key modifiers
  **
  once EventListeners onMouseDown() { EventListeners() }

  **
  ** Callback for mouse button released event on this widget.
  **
  ** Event id fired:
  **   - `EventId.mouseUp`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **   - `Event.count`: number of clicks
  **   - `Event.key`: key modifiers
  **
  once EventListeners onMouseUp() { EventListeners() }

  **
  ** Callback when mouse enters this widget's bounds.
  **
  ** Event id fired:
  **   - `EventId.mouseEnter`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **
  once EventListeners onMouseEnter() { EventListeners() }

  **
  ** Callback when mouse exits this widget's bounds.
  **
  ** Event id fired:
  **   - `EventId.mouseExit`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **
  once EventListeners onMouseExit() { EventListeners() }

  **
  ** Callback when mouse hovers for a moment over this widget.
  **
  ** Event id fired:
  **   - `EventId.mouseHover`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **
  once EventListeners onMouseHover() { EventListeners() }

  **
  ** Callback when mouse moves over this widget.
  **
  ** Event id fired:
  **   - `EventId.mouseMove`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **
  once EventListeners onMouseMove() { EventListeners() }

  **
  ** Callback when mouse wheel is scrolled and this widget has focus.
  **
  ** Event id fired:
  **   - `EventId.mouseWheel`
  **
  ** Event fields:
  **   - `Event.pos`: coordinate of mouse
  **   - `Event.count`: positive or negative number of scroll
  **
  once EventListeners onMouseWheel() { EventListeners() }

  **
  ** Callback for focus gained event on this widget.
  **
  ** Event id fired:
  **   - `EventId.focus`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onFocus()
  {
    EventListeners() { onModify = |->| { checkFocusListeners } }
  }

  internal native Void checkFocusListeners()

  **
  ** Callback for focus lost event on this widget.
  **
  ** Event id fired:
  **   - `EventId.blur`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onBlur()
  {
    EventListeners() { onModify = |->| { checkFocusListeners } }
  }

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this widget is the focused widget which
  ** is currently receiving all keyboard input.
  **
  native Bool hasFocus()

  **
  ** Attempt for this widget to take the keyboard focus.
  **
  native Void focus()

//////////////////////////////////////////////////////////////////////////
// Bounds
//////////////////////////////////////////////////////////////////////////

  **
  ** Position of this widget relative to its parent.
  ** If this a window, this is the position on the screen.
  **
  @Transient
  native Point pos

  **
  ** Size of this widget.
  **
  @Transient
  native Size size

  **
  ** Position and size of this widget relative to its parent.
  ** If this a window, this is the position on the screen.
  **
  Rect bounds
  {
    get { return Rect.makePosSize(pos, size) }
    set { pos = it.pos; size = it.size }
  }

  **
  ** Get the position of this widget relative to the window.
  ** If not on mounted on the screen then return null.
  **
  native Point? posOnWindow()

  **
  ** Get the position of this widget on the screen coordinate's
  ** system.  If not on mounted on the screen then return null.
  **
  native Point? posOnDisplay()

//////////////////////////////////////////////////////////////////////////
// Widget Tree
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this widget's parent or null if not mounted.
  **
  @Transient Widget? parent { private set }
  internal Void setParent(Widget p) { parent = p } // for Window.make

  **
  ** Get this widget's parent window or null if not
  ** mounted under a Window widget.
  **
  Window? window()
  {
    Widget? x := this
    while (x != null)
    {
      if (x is Window) return (Window)x
      x = x.parent
    }
    return null
  }

  **
  ** Iterate the children widgets.
  **
  Void each(|Widget w, Int i| f)
  {
    kids.each(f)
  }

  **
  ** Get the children widgets.
  **
  Widget[] children() { return kids.ro }

  **
  ** Add a child widget.  If child is null, then do nothing.
  ** If child is already parented throw ArgErr.  Return this.
  **
  @Operator virtual This add(Widget? child)
  {
    if (child == null) return this
    if (child.parent != null)
      throw ArgErr("Child already parented: $child")
    child.parent = this
    kids.add(child)
    try { child.attach } catch (Err e) { e.trace }
    return this
  }

  **
  ** Add all widgets in list by calling `add` on each widget.
  ** Return this.
  **
  virtual This addAll(Widget?[] children)
  {
    children.each |kid| { add(kid) }
    return this
  }

  **
  ** Remove a child widget.  If child is null, then do
  ** nothing.  If this widget is not the child's current
  ** parent throw ArgErr.  Return this.
  **
  virtual This remove(Widget? child)
  {
    if (child == null) return this
    try { child.detach } catch (Err e) { e.trace }
    if (kids.removeSame(child) == null)
      throw ArgErr("not my child: $child")
    child.parent = null
    return this
  }

  **
  ** Remove all child widgets.  Return this.
  **
  virtual This removeAll()
  {
    kids.dup.each |Widget kid| { remove(kid) }
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  **
  ** Relayout this widget.  This method is called when something
  ** has changed and we need to recompute the layout of this
  ** widget's children.  Return this.
  **
  native This relayout()

  **
  ** Set this widget's size to its preferred size.  Return this.
  **
  native This pack()

  **
  ** Compute the preferred size of this widget.  The hints indicate
  ** constraints the widget should consider in its calculations.
  ** If no constraints are known for width, then 'hints.w' will be
  ** null.  If no constraints are known for height, then 'hints.h'
  ** will be null.
  **
  virtual native Size prefSize(Hints hints := Hints.defVal)

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  **
  ** Repaint this widget.  If the dirty rectangle is null,
  ** then the whole widget is repainted.
  **
  native Void repaint(Rect? dirty := null)

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  ** Is this widget attached to a native peer?
  internal native Bool attached()

  ** Attach to a native peer
  private native Void attach()

  ** Detach from native peer
  private native Void detach()

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  @Transient
  internal Widget[] kids := Widget[,]

}