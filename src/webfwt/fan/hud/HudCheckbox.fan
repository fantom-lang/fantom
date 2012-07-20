//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 2012  Andy Frank  Creation
//

using fwt
using gfx

**
** HudCheckbox.
**
@NoDoc
@Js
class HudCheckbox : WebLabel
{
  ** Constructor
  new make(|This|? f := null)
  {
    fg = Color("#fff")
    if (f != null) f(this)
    onMouseUp.add |e|
    {
      selected = !selected
      update
      onAction.fire(Event { id=EventId.action; widget=this; data=selected })
    }
    update
  }

  ** Selection state for checbox.
  Bool selected := false
  {
    set { &selected=it; update }
  }

  ** Callback for selection changes.
  once EventListeners onAction() { EventListeners() }

  ** Update selection state.
  private Void update()
  {
    image = selected ? imgOn : imgOff
    relayout
  }

  private static const Image imgOff := Image(`fan://webfwt/res/img/hud-checkbox-off.png`)
  private static const Image imgOn  := Image(`fan://webfwt/res/img/hud-checkbox-on.png`)
}

