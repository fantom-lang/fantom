//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
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

public class PanePeer
  extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static PanePeer make(fan.fwt.Pane self)
    throws Exception
  {
    PanePeer peer = new PanePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    Composite c = new Composite((Composite)parent, 0);
    c.setLayout(new PaneLayout());
    return c;
  }

//////////////////////////////////////////////////////////////////////////
// PaneLayout
//////////////////////////////////////////////////////////////////////////

  class PaneLayout extends Layout
  {
    protected Point computeSize(Composite composite, int wHint, int hHint, boolean flushCache)
    {
      Hints hints = Hints.make(
        wHint == SWT.DEFAULT ? null : Long.valueOf(wHint),
        hHint == SWT.DEFAULT ? null : Long.valueOf(hHint));
      Size s = ((Pane)self).prefSize(hints);
      if (s == null) return new Point(20, 20);
      return new Point((int)s.w, (int)s.h);
    }

    protected void layout(Composite composite, boolean flushCache)
    {
      Rectangle rect = composite.getClientArea();
      if (rect.x != 0 || rect.y != 0)
        System.out.println("WARNING: we got a problem houston with client area " + composite);
      ((Pane)self).onLayout();
    }
  }

}