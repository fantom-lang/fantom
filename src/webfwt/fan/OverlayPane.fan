//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Apr 2013  Andy Frank  Creation
//

using gfx
using fwt

**
** OverlayPane is a dismissable pane that floats above all other content.
**
@Js
class OverlayPane : ContentPane
{
  ** Open this overlay at the coordinates relative to the parent widget.
  native This open(Widget parent, Point pos)

  ** Close this overlay.
  native Void close()

  ** Callback function directly before overlay is opened.
  **  - id: `fwt::EventId.open`
  once EventListeners onBeforeOpen() { EventListeners() }

  ** Callback function when overlay is open.
  **  - id: `fwt::EventId.open`
  once EventListeners onOpen() { EventListeners() }

  ** Callback function when overlay is closed.
  **  - id: `fwt::EventId.close`
  once EventListeners onClose() { EventListeners() }

  ** Horizontal alignment of overlay, using 'open(pos)' as origin.
  Halign halign := Halign.right

  ** Vertial alignment of overlay, using 'open(pos)' as origin.
  Valign valign := Valign.bottom

  ** Animate overlay open/close/resize.  Must be configured before 'open'.
  Bool animate := true

  ** Move overlay to new point, where point is relative to parent
  ** widget passed to 'open'.
  native Void move(Point pos)
}