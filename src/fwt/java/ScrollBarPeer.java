//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 09  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class ScrollBarPeer
  extends WidgetPeer
  implements SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ScrollBarPeer make(fan.fwt.ScrollBar self)
    throws Exception
  {
    ScrollBarPeer peer = new ScrollBarPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  void attachTo(Widget control)
  {
    super.attachTo(control);
    ScrollBar sb = (ScrollBar)control;
    sb.addSelectionListener(this);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public Orientation orientation(fan.fwt.ScrollBar self)
  {
    return orientation(control.getStyle());
  }

  // Int val := 0
  public long val(fan.fwt.ScrollBar self) { return val.get(); }
  public void val(fan.fwt.ScrollBar self, long v) { val.set(v); }
  public final Prop.IntProp val = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ScrollBar)w).getSelection(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setSelection(v); }
  };

  // Int min := 0
  public long min(fan.fwt.ScrollBar self) { return min.get(); }
  public void min(fan.fwt.ScrollBar self, long v) { min.set(v); }
  public final Prop.IntProp min = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ScrollBar)w).getMinimum(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setMinimum(v); }
  };

  // Int max := 100
  public long max(fan.fwt.ScrollBar self) { return max.get(); }
  public void max(fan.fwt.ScrollBar self, long v) { max.set(v); }
  public final Prop.IntProp max = new Prop.IntProp(this, 100)
  {
    public int get(Widget w) { return ((ScrollBar)w).getMaximum(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setMaximum(v); }
  };

  // Int thumb := 10
  public long thumb(fan.fwt.ScrollBar self) { return thumb.get(); }
  public void thumb(fan.fwt.ScrollBar self, long v) { thumb.set(v); }
  public final Prop.IntProp thumb = new Prop.IntProp(this, 10)
  {
    public int get(Widget w) { return ((ScrollBar)w).getThumb(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setThumb(v); }
  };

  // Int page := 10
  public long page(fan.fwt.ScrollBar self) { return page.get(); }
  public void page(fan.fwt.ScrollBar self, long v) { page.set(v); }
  public final Prop.IntProp page = new Prop.IntProp(this, 10)
  {
    public int get(Widget w) { return ((ScrollBar)w).getPageIncrement(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setPageIncrement(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void widgetDefaultSelected(SelectionEvent se) {}

  public void widgetSelected(SelectionEvent se)
  {
    ScrollBar sb = (ScrollBar)control;
    fan.fwt.Event fe = event(EventId.modified);
    fe.data = Long.valueOf(sb.getSelection());
    ((fan.fwt.ScrollBar)self).onModify().fire(fe);
  }
}