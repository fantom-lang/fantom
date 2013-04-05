//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Andy Frank  Creation
//

using gfx
using fwt

**
** Popup displays a content widget in a popup window.
**
@Js
class Popup : ContentPane
{
  ** Open this popup at the coordinates relative to the parent widget.
  native This open(Widget parent, Point pos)

  ** Close this popup.
  native Void close()

  ** Find and return the first parent Popup for the given widget, or
  ** null if no parent Popup can be found.
  static Popup? find(Widget w)
  {
    p := w.parent
    while (p != null && p isnot Popup) p = p.parent
    return p
  }

  ** Callback function directly before popup is opened.
  **  - id: `fwt::EventId.open`
  once EventListeners onBeforeOpen() { EventListeners() }

  ** Callback function when popup is open.
  **  - id: `fwt::EventId.open`
  once EventListeners onOpen() { EventListeners() }

  ** Callback function when popup is closed.
  **  - id: `fwt::EventId.close`
  once EventListeners onClose() { EventListeners() }

  ** Horizontal alignment of popup, using 'open(pos)' as origin.
  Halign halign := Halign.right

  ** Vertial alignment of popup, using 'open(pos)' as origin.
  Valign valign := Valign.bottom

  ** Animate popup open/close/resize.  Must be configured before 'open'.
  Bool animate := true

  ** Move popup to new point, where point is relative to parent
  ** widget passed to 'open'.
  native Void move(Point pos)

  ** Attach an "onPopup" event handler to the given widget.
  static Void attach(Widget w, |Event e| f)
  {
    active := false
    w.onMouseDown.add { active=true }
    w.onMouseUp.add |e|
    {
      if (!active) return
      f(e)
      active = false
    }
  }
}