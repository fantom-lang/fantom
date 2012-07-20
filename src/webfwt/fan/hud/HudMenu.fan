//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** HudMenu displays a menu in a HudPopup.
**
@Js
class HudMenu : HudPopup
{

  ** Constructor.
  new make(|This|? f := null) : super(null)
  {
    f(this)
    rows := RowPane { cols=[ColLayout { it.insets=Insets(2,12) }] }
    rows.onMouseDown.add |e|
    {
      i := rows.rowAt(e.pos)
      if (i == null) return
      selected = items[i]
      selectedIndex = i
      rows.rowBg = [i:bgSelect]
      rows.relayout
    }
    rows.onMouseUp.add |e|
    {
      if (selected == null) return
      close
    }
    items.each |item,i|
    {
      rows.add(Label {
        it.text = item.toStr
        it.fg   = Color.white
      })
    }
    insets = Insets(4,0)
    body = rows
  }

  ** Menu items.
  Obj[] items

  ** Selected menu item, or null if menu was cancelled.
  Obj? selected := null

  ** Selected menu item index, or null if menu was cancelled.
  Int? selectedIndex := null

  ** selection bg color
  private static const Color bgSelect := Color("#3d80df")
}


