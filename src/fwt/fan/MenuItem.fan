//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

using gfx

**
** MenuItem is an individual item on a Menu.
**
@Js
@Serializable
class MenuItem : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Make a menu item for the specified command.
  **
  new makeCommand(Command c)
  {
    mode = c.mode.toMenuItemMode
    command = c
  }

  **
  ** Callback function when menu is selected.
  **
  ** Event id fired:
  **   - `EventId.action`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onAction() { EventListeners() }

  **
  ** Mode defines the menu item's style.  Normal items are
  ** one of check, push, radio, or sep.  The default is push.
  ** All instances of `Menu` have a mode of menu.  This field
  ** cannot be changed once the item is constructed.
  **
  const MenuItemMode mode := this is Menu ? MenuItemMode.menu : MenuItemMode.push

  **
  ** The button's selection state (if check or radio).
  ** Defaults to false.
  **
  native Bool selected

  **
  ** Text of the menu item's label. Defaults to "".
  **
  native Str text

  **
  ** Accelerator for menu item.
  **
  native Key? accelerator

  **
  ** Image to display on menu item. Defaults to null.
  **
  native Image? image

  **
  ** Command associated with this menu item.  Setting the
  ** command automatically maps the text, icon, enable state,
  ** and eventing to the command.
  **
  Command? command
  {
    set
    {
      newVal := it
      this.&command?.unregister(this)
      this.&command = newVal
      if (newVal != null)
      {
        enabled     = newVal.enabled
        text        = newVal.name
        image       = newVal.icon
        accelerator = newVal.accelerator
        selected = newVal.selected
        onAction.add |Event e|
        {
          newVal.selected = this.selected
          newVal.invoke(e)
        }
        newVal.register(this)
      }
    }
  }

}