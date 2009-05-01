//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class MenuItemPeer
  extends WidgetPeer
  implements SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MenuItemPeer make(fan.fwt.MenuItem self)
    throws Exception
  {
    MenuItemPeer peer = new MenuItemPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    // the parent of a MenuItem is always a Menu which
    // has both a Menu and MenuItem SWT control, we always
    // want to use the Menu as our parent
    Menu parentMenu = ((MenuPeer)self.parent().peer).menu;

    fan.fwt.MenuItem self = (fan.fwt.MenuItem)this.self;
    MenuItem m = new MenuItem(parentMenu, mode(self.mode));
    control = m;
    m.addSelectionListener(this);
    return m;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  //
  // Note: these fields only apply when the control is a MenuItem,
  // in some cases it might be a Menu, in which case we ignore the
  // sets; see MenuPeer.create for specific cases
  //

  // Bool selected := false
  public boolean selected(fan.fwt.MenuItem self) { return selected.get(); }
  public void selected(fan.fwt.MenuItem self, boolean v) { selected.set(v); }
  public final Prop.BoolProp selected = new Prop.BoolProp(this, false)
  {
    public boolean get(Widget w) { return (w instanceof MenuItem) ? ((MenuItem)w).getSelection() : false; }
    public void set(Widget w, boolean v) { if (w instanceof MenuItem) ((MenuItem)w).setSelection(v); }
  };

  // Str text := ""
  public String text(fan.fwt.MenuItem self) { return text.get(); }
  public void text(fan.fwt.MenuItem self, String v) { text.set(v); }
  public final Prop.StrProp text = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return (w instanceof MenuItem) ? ((MenuItem)w).getText() : ""; }
    public void set(Widget w, String v)
    {
      if (!(w instanceof MenuItem)) return;
      Key acc = ((fan.fwt.MenuItem)self).accelerator();
      if (acc != null) v += "\t" + acc;
      ((MenuItem)w).setText(v);
    }
  };

  // Key accelerator := null
  public fan.fwt.Key accelerator (fan.fwt.MenuItem self) { return accelerator.get(); }
  public void accelerator (fan.fwt.MenuItem self, fan.fwt.Key v) { accelerator.set(v); }
  public final Prop.KeyProp accelerator = new Prop.KeyProp (this)
  {
    public void set(Widget w, int v) { if (w instanceof MenuItem && !isTopMenu()) ((MenuItem)w).setAccelerator(v); }
  };

  // Image image := null
  public fan.gfx.Image image(fan.fwt.MenuItem self) { return image.get(); }
  public void image(fan.fwt.MenuItem self, fan.gfx.Image v) { image.set(v); }
  public final Prop.ImageProp image = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { if (w instanceof MenuItem && !isTopMenu()) ((MenuItem)w).setImage(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void widgetSelected(SelectionEvent event)
  {
    fan.fwt.MenuItem self = (fan.fwt.MenuItem)this.self;
    self.onAction().fire(event(EventId.action));
  }

  public void widgetDefaultSelected(SelectionEvent event)
  {
    // not used
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  boolean isTopMenu()
  {
    // return if this is a Menu under a Menu
    return self instanceof fan.fwt.Menu && self.parent() instanceof fan.fwt.Menu;
  }

  static int mode(MenuItemMode mode)
  {
    if (mode == MenuItemMode.push)  return SWT.PUSH;
    if (mode == MenuItemMode.check) return SWT.CHECK;
    if (mode == MenuItemMode.radio) return SWT.RADIO;
    if (mode == MenuItemMode.sep)   return SWT.SEPARATOR;
    throw new IllegalStateException(""+mode);
  }

}