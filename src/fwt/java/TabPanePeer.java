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
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;

public class TabPanePeer extends WidgetPeer
{

  public static TabPanePeer make(fan.fwt.TabPane self)
    throws Exception
  {
    TabPanePeer peer = new TabPanePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    return new TabFolder((Composite)parent, SWT.TOP);
  }

}