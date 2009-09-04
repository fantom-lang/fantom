//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.custom.ScrolledComposite;

public class ScrollPanePeer extends PanePeer
{

  public static ScrollPanePeer make(fan.fwt.ScrollPane self)
    throws Exception
  {
    ScrollPanePeer peer = new ScrollPanePeer();
    ((fan.fwt.Pane)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    ScrollPane self = (ScrollPane)this.self;

    int style = SWT.H_SCROLL | SWT.V_SCROLL;
    if (self.border)  style |= SWT.BORDER;

    ScrolledComposite c = new ScrolledComposite((Composite)parent, style);
    c.setExpandHorizontal(true);
    c.setExpandVertical(true);
    c.setMinSize(100,100);

    ScrollBar hbar = c.getHorizontalBar();
    ScrollBar vbar = c.getVerticalBar();
    if (hbar != null) ((ScrollBarPeer)self.hbar().peer).attachToScrollable(c, hbar);
    if (vbar != null) ((ScrollBarPeer)self.vbar().peer).attachToScrollable(c, vbar);

    this.control = c;
    return c;
  }

  void onSizeChange() { ((ScrollPane)self).onLayout(); }

  public void setMinSize(fan.fwt.ScrollPane self, fan.gfx.Size size)
  {
    ScrolledComposite sc = (ScrolledComposite)this.control;
    if (sc == null) return;
    sc.setMinSize((int)size.w, (int)size.h);
  }

}