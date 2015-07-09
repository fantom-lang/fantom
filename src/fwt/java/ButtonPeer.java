//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class ButtonPeer
  extends WidgetPeer
  implements SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ButtonPeer make(fan.fwt.Button self)
    throws Exception
  {
    ButtonPeer peer = new ButtonPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.Button self = (fan.fwt.Button)this.self;
    if (parent instanceof ToolBar)
    {
      ToolItem b = new ToolItem((ToolBar)parent, mode(self.mode, true));
      control = b;
      b.addSelectionListener(this);
      return b;
    }
    else
    {
      Button b = new Button((Composite)parent, mode(self.mode, false));
      control = b;
      b.addSelectionListener(this);
      return b;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  // Bool selected := false
  public boolean selected(fan.fwt.Button self) { return selected.get(); }
  public void selected(fan.fwt.Button self, boolean v) { selected.set(v); }
  public final Prop.BoolProp selected = new Prop.BoolProp(this, false)
  {
    public boolean get(Widget w) { return (w instanceof Button) ? ((Button)w).getSelection() : ((ToolItem)w).getSelection(); }
    public void set(Widget w, boolean v) { if (w instanceof Button) ((Button)w).setSelection(v); else ((ToolItem)w).setSelection(v); }
  };

  // Str text := ""
  public String text(fan.fwt.Button self) { return text.get(); }
  public void text(fan.fwt.Button self, String v) { text.set(v); }
  public final Prop.StrProp text = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return (w instanceof Button) ? ((Button)w).getText() : ((ToolItem)w).getText(); }
    public void set(Widget w, String v) { if (w instanceof Button) ((Button)w).setText(v); else ((ToolItem)w).setText(v); }
  };

  // Str toolTip := ""
  public String toolTip(fan.fwt.Button self) { return toolTip.get(); }
  public void toolTip(fan.fwt.Button self, String v) { toolTip.set(v); }
  public final Prop.StrProp toolTip = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return (w instanceof Button) ? ((Button)w).getToolTipText() : ((ToolItem)w).getToolTipText(); }
    public void set(Widget w, String v) { if (w instanceof Button) ((Button)w).setToolTipText(v); else ((ToolItem)w).setToolTipText(v); }
  };

  // Image image := null
  public fan.gfx.Image image(fan.fwt.Button self) { return image.get(); }
  public void image(fan.fwt.Button self, fan.gfx.Image v) { image.set(v); }
  public final Prop.ImageProp image = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { if (w instanceof Button) ((Button)w).setImage(v); else ((ToolItem)w).setImage(v); }
  };

  // Font font := null
  public fan.gfx.Font font(fan.fwt.Button self) { return font.get(); }
  public void font(fan.fwt.Button self, fan.gfx.Font v) { font.set(v); }
  public final Prop.FontProp font = new Prop.FontProp(this)
  {
    public void set(Widget w, Font v) { if (w instanceof Button) ((Button)w).setFont(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void handleEvent(Event se)
  {
    if (se.type == SWT.MouseDown) lastMousePos = fan.gfx.Point.make(se.x, se.y);
    super.handleEvent(se);
  }

  public void widgetSelected(SelectionEvent event)
  {
    fan.fwt.Event fe = event(EventId.action);
    fe.pos = lastMousePos;

    fan.fwt.Button self = (fan.fwt.Button)this.self;
    self.onAction().fire(fe);
  }

  public void widgetDefaultSelected(SelectionEvent event)
  {
    // not used
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static int mode(ButtonMode mode, boolean toolbar)
  {
    if (mode == ButtonMode.push)   return SWT.PUSH;
    if (mode == ButtonMode.check)  return SWT.CHECK;
    if (mode == ButtonMode.toggle) return toolbar ? SWT.CHECK : SWT.TOGGLE;
    if (mode == ButtonMode.radio)  return SWT.RADIO;
    if (mode == ButtonMode.sep)    return SWT.SEPARATOR;
    throw new IllegalStateException(""+mode);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  fan.gfx.Point lastMousePos = fan.gfx.Point.defVal;

}