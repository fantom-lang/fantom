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
    ScrolledComposite c = new ScrolledComposite((Composite)parent, SWT.H_SCROLL|SWT.V_SCROLL);
    c.setExpandHorizontal(true);
    c.setExpandVertical(true);
    c.setMinSize(400,400);  // TODO, see ScrollPane.fan
    this.control = c;
    return c;
  }
}
