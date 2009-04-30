//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

using gfx

**
** Menu contains MenuItems.  Menu is also itself a MenuItem
** when nested inside other Menus.
**
class Menu : MenuItem
{

  **
  ** Default constructor.
  **
  new make() : super.make() {}

  **
  ** Callback function when menu is opened.  This callback
  ** provides a change to build a lazily populated menu.
  **
  ** Event id fired:
  **  - `EventId.open`
  **
  ** Event fields:
  **   - none
  **
  @transient readonly EventListeners onOpen:= EventListeners()

  **
  ** Open this menu as a popup at the coordinates relative to
  ** the parent widget.  If the pos is null, then open at the
  ** location of the mouse click.  This method blocks until the
  ** menu is closed.
  **
  native This open(Widget parent, Point? pos := null)

  **
  ** Add a menu item for the specified command.  Default
  ** implementation is to add an item without the icon.
  **
  MenuItem addCommand(Command c)
  {
    item := MenuItem.makeCommand(c) { it.image = null }
    add(item)
    return item
  }

  **
  ** Add a separator to the menu.
  **
  Void addSep()
  {
    item := MenuItem { it.mode = MenuItemMode.sep }
    add(item)
  }

  override This add(Widget? kid)
  {
    if (kid isnot MenuItem)
      throw ArgErr("Child of Menu must be MenuItem, not $kid.type")
    super.add(kid)
    return this
  }

}