//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** Menu contains MenuItems.  Menu is also itself a MenuItem
** when nested inside other Menus.
**
class Menu : MenuItem
{

  **
  ** Open this menu as a popup at the coordinates relative to
  ** the parent widget.  If the pos is null, then open at the
  ** location of the mouse click.  This method blocks until the
  ** menu is closed.
  **
  native This open(Widget parent, Point pos := null)

  override This add(Widget kid)
  {
    if (kid isnot MenuItem)
      throw ArgErr("Child of Menu must be MenuItem, not $kid.type")
    super.add(kid)
    return this
  }

}