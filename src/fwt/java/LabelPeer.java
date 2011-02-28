//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.Halign;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.custom.CLabel;

public class LabelPeer extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static LabelPeer make(fan.fwt.Label self)
    throws Exception
  {
    LabelPeer peer = new LabelPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    return new CLabel((Composite)parent, 0);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Str text := ""
  public String text(fan.fwt.Label self) { return text.get(); }
  public void text(fan.fwt.Label self, String v) { text.set(v); }
  public final Prop.StrProp text = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return text.val; } // CLabel doesn't perserve my text
    public void set(Widget w, String v) { text.val = v; ((CLabel)w).setText(v); }
  };

  // Image image := null
  public fan.gfx.Image image(fan.fwt.Label self) { return image.get(); }
  public void image(fan.fwt.Label self, fan.gfx.Image v) { image.set(v); }
  public final Prop.ImageProp image = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { ((CLabel)w).setImage(v); }
  };

  // Color fg := null
  public fan.gfx.Color fg(fan.fwt.Label self) { return fg.get(); }
  public void fg(fan.fwt.Label self, fan.gfx.Color v) { fg.set(v); }
  public final Prop.ColorProp fg = new Prop.ColorProp(this)
  {
    public void set(Widget w, Color v) { ((CLabel)w).setForeground(v); }
  };

  // Color bg := null
  public fan.gfx.Color bg(fan.fwt.Label self) { return bg.get(); }
  public void bg(fan.fwt.Label self, fan.gfx.Color v) { bg.set(v); }
  public final Prop.ColorProp bg = new Prop.ColorProp(this)
  {
    public void set(Widget w, Color v) { ((CLabel)w).setBackground(v); }
  };

  // Halign halign := left
  public Halign halign(fan.fwt.Label self) { return halign.get(); }
  public void halign(fan.fwt.Label self, Halign v) { halign.set(v); }
  public final Prop.HalignProp halign = new Prop.HalignProp(this, Halign.left)
  {
    public void set(Widget w, int v) { ((CLabel)w).setAlignment(v); }
  };

  // Font font := null
  public fan.gfx.Font font(fan.fwt.Label self) { return font.get(); }
  public void font(fan.fwt.Label self, fan.gfx.Font v) { font.set(v); }
  public final Prop.FontProp font = new Prop.FontProp(this)
  {
    public void set(Widget w, Font v) { ((CLabel)w).setFont(v); }
  };

}