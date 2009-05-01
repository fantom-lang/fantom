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
import org.eclipse.swt.widgets.Widget;

public class TabPeer extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TabPeer make(Tab self)
    throws Exception
  {
    TabPeer peer = new TabPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    return new TabItem((TabFolder)parent, SWT.NONE);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Str text := ""
  public String text(Tab self) { return text.get(); }
  public void text(Tab self, String v) { text.set(v); }
  public final Prop.StrProp text = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return ((TabItem)w).getText(); }
    public void set(Widget w, String v) { ((TabItem)w).setText(v);  }
  };

  // Image image := null
  public fan.gfx.Image image(Tab self) { return image.get(); }
  public void image(Tab self, fan.gfx.Image v) { image.set(v); }
  public final Prop.ImageProp image = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { ((TabItem)w).setImage(v); }
  };

}