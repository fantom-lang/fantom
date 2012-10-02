//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

using gfx

**
** Event models a user input event for callbacks.
**
@Js
class Event
{

  **
  ** Type identifier of the event.  This field is always available.
  **
  EventId id := EventId.unknown

  **
  ** Widget which generated the event.  This will be null for model events.
  **
  Widget? widget

  **
  ** Convenience for 'widget?.window'.
  **
  Window? window() { return widget?.window }

  **
  ** Index for list based events. For table events this
  ** is the row index.
  **
  Int? index

  **
  ** Used as the zero based text offset for text
  ** and rich text widget events.
  **
  Int? offset

  **
  ** Number of characters for text and rich text widget events.
  **
  Int? size

  **
  ** Mouse button number pressed
  **
  Int? button

  **
  ** Unicode character represented by a key event.
  **
  Int? keyChar

  **
  ** Key code and modifiers.
  **
  Key? key

  **
  ** Coordinate of event.  For mouse events this is the mouse
  ** coordinate relative to the widget.
  **
  Point? pos

  **
  ** Delta value of event.  For mouse wheel events this is the
  ** amount the mouse wheel has traveled.
  **
  Point? delta

  **
  ** Number of mouse clicks.
  **
  Int? count

  **
  ** Event specific user data.
  **
  Obj? data

  **
  ** Return if this a single click, mouse up on button 3
  **
  Bool isPopupTrigger()
  {
    id === EventId.mouseUp && button == 3 && count == 1
  }

  **
  ** If this a popup event, then this field should be set
  ** to the menu item to open.  Setting this field to a nonnull
  ** value implicitly consumes the event.
  **
  Menu? popup { set { &popup = it; if (it != null) consume } }

  **
  ** Has this event been "consumed"?  Once an event
  ** is consumed it ceases to propagate or be processed.
  ** Also see `consume`.
  **
  Bool consumed := false

  **
  ** Convenience for setting `consumed` to true.
  **
  Void consume() { consumed = true }

  override Str toStr()
  {
    s := StrBuf()
    s.add("Event { id=").add(id)
    if (index != null)   s.join("index=").add(index)
    if (offset != null)  s.join("offset=").add(offset)
    if (size != null)    s.join("size=").add(size)
    if (button != null)  s.join("button=").add(button)
    if (keyChar != null) s.join("keyChar=").add(keyChar.toChar.toCode('\'', true))
    if (key != null)     s.join("key=").add(key)
    if (pos != null)     s.join("pos=").add(pos)
    if (count != null)   s.join("count=").add(count)
    if (delta != null)   s.join("delta=").add(delta)
    if (data != null)    s.join("data=").add(data)
    if (consumed)        s.join("consumed")
    s.add(" }")
    return s.toStr
  }
}

**************************************************************************
** EventId
**************************************************************************

**
** EventId identifies the type of widget `Event`.
**
@Js
enum class EventId
{
  unknown,
  focus,
  blur,
  keyDown,
  keyUp,
  mouseDown,
  mouseUp,
  mouseEnter,
  mouseExit,
  mouseHover,
  mouseMove,
  mouseWheel,
  action,
  modified,
  verify,
  verifyKey,
  select,
  caret,
  hyperlink,
  popup,
  open,
  close,
  active,
  inactive,
  iconified,
  deiconified
}

**************************************************************************
** EventListeners
**************************************************************************

**
** EventListeners manages a list of event callback functions.
**
@Js
class EventListeners
{
  ** Get the list of registered callback functions.
  |Event|[] list() { return listeners.ro }

  ** Return if `size` is zero.
  Bool isEmpty() { return listeners.isEmpty }

  ** Return number of registered callback functions.
  Int size() { return listeners.size }

  ** Add a listener callback function
  Void add(|Event| cb) { listeners.add(cb); modified }

  ** Remove a listener callback function
  Void remove(|Event| cb) { listeners.remove(cb); modified }

  ** Fire the event to all the listeners
  Void fire(Event? event)
  {
    listeners.each |cb|
    {
      if (event?.consumed == true) return
      if (Env.cur.runtime == "js") cb(event)
      else
      {
        try { cb(event) }
        catch (Err e) { echo("event: $event"); e.trace }
      }
    }
  }

  ** Fire internal modified event
  internal Void modified()
  {
    try
      onModify?.call(this)
    catch (Err e)
      e.trace
  }

  ** List of listeners
  private |Event|[] listeners := |Event|[,]

  ** Callback when list of listeners is modified
  internal |EventListeners|? onModify
}