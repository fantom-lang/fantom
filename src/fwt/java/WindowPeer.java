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
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
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
// Sizing
//////////////////////////////////////////////////////////////////////////

  void onPosChange()  { explicitPos = true;  }
  void onSizeChange() { explicitSize = true; }

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
    // if already open
    if (control != null) throw Err.make("Window already open").val;

    // initialize with clean slate
    result = null;

    // create SWT shell
    Env env = Env.get();
    Shell shell;
    fan.fwt.Widget parent = self.parent();
    Shell parentShell = parent == null ? null : (Shell)parent.peer.control;
    if (parentShell == null)
    {
      shell = new Shell(env.display, style(self));
    }
    else
    {
      shell = new Shell(parentShell, style(self));
    }
    shell.setLayout(new FillLayout());
    attachTo(shell);

    // if not explicitly sized, then use prefSize - but
    // make sure not bigger than monitor (at this point we
    // don't know which monitor so assume primary monitor)
    if (!explicitSize)
    {
      shell.pack();
      Rectangle mb = shell.getBounds();
      Rectangle pb = env.display.getPrimaryMonitor().getClientArea();
      int pw = Math.min(mb.width, pb.width-50);
      int ph = Math.min(mb.height, pb.height-50);
      shell.setSize(pw, ph);
    }

    // if not explicitly positioned, then center on
    // parent shell (or primary monitor)
    if (!explicitPos)
    {
      Rectangle pb = parentShell == null ?
        env.display.getPrimaryMonitor().getClientArea() :
        parentShell.getBounds();
      Rectangle mb = shell.getBounds();
      int cx = pb.x + (pb.width - mb.width)/2;
      int cy = pb.y + (pb.height - mb.height)/2;
      shell.setLocation(cx, cy);
    }

    // ensure that window isn't off the display; this
    // still might cover multiple monitors though, but
    // provides a safe sanity check
    Rectangle mb = shell.getBounds();
    Rectangle db = env.display.getClientArea();
    if (mb.width > db.width) mb.width = db.width;
    if (mb.height > db.height) mb.height = db.height;
    if (mb.x + mb.width > db.x + db.width) mb.x = db.x + db.width - mb.width;
    if (mb.x < db.x) mb.x = db.x;
    if (mb.y + mb.height > db.y + db.height) mb.y = db.y + db.height - mb.height;
    if (mb.y < db.y) mb.y = db.y;
    shell.setBounds(mb);

    // open
    shell.open();

    // block until dialog is closed
    env.eventLoop(shell);

    // cleanup
    detach(self);
    explicitPos = explicitSize = false;
    return result;
  }

  public void close(Window self, Obj result)
  {
    if (control == null) return;
    this.result = result;
    Shell shell = (Shell)control;
    shell.close();
    detach(self);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  boolean explicitPos;    // has pos been explicitly configured?
  boolean explicitSize;   // has size been explicitly configured?
  Obj result;
}