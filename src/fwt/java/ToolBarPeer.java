//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.Widget;

public class ToolBarPeer extends WidgetPeer
{

  public static ToolBarPeer make(fan.fwt.ToolBar self)
    throws Exception
  {
    ToolBarPeer peer = new ToolBarPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.ToolBar self = (fan.fwt.ToolBar)this.self;
    return new ToolBar((Composite)parent, orientation(self.orientation));
  }

}
