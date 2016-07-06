//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2016  Andy Frank  Creation
//

using dom

**
** Combo combines a TextField and ListButton into a single widget
** that allows a user to select from a list or manually enter a
** value.
**
** See also: [pod doc]`pod-doc#combo`
**
@Js class Combo : Elem
{
  new make() : super("div")
  {
    this.field = TextField
    {
      it.onEvent(EventType.keyDown, false) |e|
      {
        if (e.key == Key.down)
        {
          e.stop
          button.openPopup
        }
      }
    }

    this.button = ListButton
    {
      it.isCombo = true
      it.onSelect
      {
        field.val = button.sel.item
        field.focus
      }
    }

    this.style.addClass("domkit-Combo")
    this.add(field)
    this.add(button)
  }

  ** TextField component of Combo.
  TextField field { private set }

  ** The current list items for Combo.
  Str[] items
  {
    get { button.items }
    set { button.items = it }
  }

  override Bool? enabled
  {
    get { field.enabled }
    set { field.enabled = button.enabled = it }
  }

  private ListButton button
}