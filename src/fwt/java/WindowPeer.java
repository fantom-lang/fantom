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
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.layout.*;

public class WindowPeer extends PanePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static WindowPeer make(fan.fwt.Window self)
    throws Exception
  {
    WindowPeer peer = new WindowPeer();
    ((fan.fwt.Pane)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    // window uses open, not normal attach process
    throw new IllegalStateException();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Str title := ""
  public Str title(Window self) { return title.get(); }
  public void title(Window self, Str v) { title.set(v); }
  public final Prop.StrProp title = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return ((Shell)w).getText(); }
    public void set(Widget w, String v) { ((Shell)w).setText(v);  }
  };

  // Image icon := null
  public fan.fwt.Image icon(Window self) { return icon.get(); }
  public void icon(Window self, fan.fwt.Image v) { icon.set(v); }
  public final Prop.ImageProp icon = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { ((Shell)w).setImage(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  int style(Window self)
  {
    int style = defaultStyle();

    if (self.mode == WindowMode.modeless)         style |= SWT.MODELESS;
    else if (self.mode == WindowMode.windowModal) style |= SWT.PRIMARY_MODAL;
    else if (self.mode == WindowMode.appModal)    style |= SWT.APPLICATION_MODAL;
    else if (self.mode == WindowMode.sysModal)    style |= SWT.SYSTEM_MODAL;

    if (self.alwaysOnTop.val) style |= SWT.ON_TOP;

    if (self.resizable.val) style |= SWT.RESIZE;

    return style;
  }

  int defaultStyle() { return SWT.CLOSE | SWT.TITLE | SWT.MIN | SWT.MAX; }

  public Obj open(Window self)
  {
    if (control != null) return null;

    Env env = null;
    Shell shell;
    fan.fwt.Widget parent = self.parent();
    if (parent == null)
    {
      env = Env.get();
      shell = new Shell(env.display, style(self));
    }
    else
    {
      shell = new Shell((Shell)parent.peer.control, style(self));
    }
    shell.setLayout(new FillLayout());
    attachTo(shell);

// TODO
if (self instanceof fan.fwt.Dialog) shell.pack();

    shell.open();

    if (env != null) env.eventLoop(shell);
    return null;
  }

  public void close(Window self)
  {
    if (control == null) return;
    Shell shell = (Shell)control;
    shell.close();
    detach(self);
  }

}