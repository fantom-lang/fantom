//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jun 09  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.layout.*;
import org.eclipse.swt.events.*;

public class CanvasPeer
  extends WidgetPeer
  implements PaintListener
{

  public static CanvasPeer make(fan.fwt.Canvas self)
    throws Exception
  {
    CanvasPeer peer = new CanvasPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    Canvas c = new Canvas((Composite)parent, 0)
    {
      public void drawBackground(GC gc, int x, int y, int w, int h) {}
    };
    c.addPaintListener(this);
    return c;
  }

  public void paintControl(PaintEvent e)
  {
    FwtGraphics g = new FwtGraphics(e.gc);
    ((fan.fwt.Canvas)self).onPaint(g);
  }

}