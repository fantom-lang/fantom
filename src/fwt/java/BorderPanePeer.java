//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.layout.*;
import org.eclipse.swt.events.*;

public class BorderPanePeer
  extends PanePeer
  implements PaintListener
{

  public static BorderPanePeer make(fan.fwt.BorderPane self)
    throws Exception
  {
    BorderPanePeer peer = new BorderPanePeer();
    ((fan.fwt.Pane)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    Canvas c = new Canvas((Composite)parent, 0);
    c.setLayout(new PanePeer.PaneLayout());
    c.addPaintListener(this);
    return c;
  }

  public void paintControl(PaintEvent e)
  {
    FwtGraphics g = new FwtGraphics(e);
    ((fan.fwt.BorderPane)self).onPaint(g);
  }

}