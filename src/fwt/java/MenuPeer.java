//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Widget;

public class MenuPeer extends MenuItemPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MenuPeer make(fan.fwt.Menu self)
    throws Exception
  {
    MenuPeer peer = new MenuPeer();
    ((fan.fwt.Widget)self).peer = peer;
    ((fan.fwt.MenuItem)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    // if my parent is a Menu, then create myself
    // as a cascade menu which is two SWT controls:
    //   this.control = MenuItem
    //   this.menu    = Menu
    if (self.parent() instanceof fan.fwt.Menu)
    {
      Menu parentMenu = (((MenuPeer)self.parent.peer).menu);
      menu = new Menu(parentMenu);
      MenuItem item = new MenuItem(parentMenu, SWT.CASCADE);
      item.setMenu(menu);
      return item;
    }

    // if my parent is a Shell, then create myself
    // as the menu bar which is one SWT control:
    //   this.control = this.menu = Menu
    if (parent instanceof Shell)
    {
      menu = new Menu((Shell)parent, SWT.BAR);
      ((Shell)parent).setMenuBar(menu);
      return menu;
    }

    throw new IllegalStateException("Unsupported parent for Menu: " + self.parent());
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public fan.fwt.Menu open(fan.fwt.Menu self, fan.fwt.Widget parent, fan.fwt.Point pos)
  {
    if (control != null)
      throw new IllegalStateException("Menu is already mounted");

    menu = new Menu((Control)parent.peer.control);
    attachTo(menu);
    if (pos != null)
    {
      pos = pos.translate(parent.posOnDisplay());
      menu.setLocation(new Point((int)pos.x.val, (int)pos.y.val));
    }
    menu.setVisible(true);

    Display display = Env.get().display;
    while (!menu.isDisposed() && menu.isVisible())
      if (!display.readAndDispatch())
        display.sleep();

    detach(self);
    return self;
  }

  public void detach(fan.fwt.Widget self)
  {
    super.detach(self);
    if (menu != null) { menu.dispose(); menu = null; }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Menu menu;
}