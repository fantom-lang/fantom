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

  public Window open(Window self)
  {
    if (control != null) return self;

    Env env = null;
    Shell shell;
    if (parent() == null)
    {
      env = Env.get();
      shell = new Shell(env.display);
    }
    else
    {
      shell = new Shell((Shell)parentControl());
    }
    shell.setLayout(new FillLayout());
    attachTo(shell);

    shell.open();

    if (env != null) env.eventLoop(shell);
    return self;
  }

  public Window close(Window self)
  {
    if (control == null) return self;
    Shell shell = (Shell)control;
    shell.close();
    detach(self);
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Shell shell;

}