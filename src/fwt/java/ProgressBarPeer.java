//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Sep 08  Andy Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.ProgressBar;
import org.eclipse.swt.widgets.Widget;

public class ProgressBarPeer
  extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ProgressBarPeer make(fan.fwt.ProgressBar self)
    throws Exception
  {
    ProgressBarPeer peer = new ProgressBarPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.ProgressBar self = (fan.fwt.ProgressBar)this.self;
    int style = self.indeterminate ? SWT.INDETERMINATE : 0;
    return new ProgressBar((Composite)parent, style);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Int val := 0
  public long val(fan.fwt.ProgressBar self) { return val.get(); }
  public void val(fan.fwt.ProgressBar self, long v) { val.set(v); }
  public final Prop.IntProp val = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ProgressBar)w).getSelection(); }
    public void set(Widget w, int v) { ((ProgressBar)w).setSelection(v); }
  };

  // Int min := 0
  public long min(fan.fwt.ProgressBar self) { return min.get(); }
  public void min(fan.fwt.ProgressBar self, long v) { min.set(v); }
  public final Prop.IntProp min = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ProgressBar)w).getMinimum(); }
    public void set(Widget w, int v) { ((ProgressBar)w).setMinimum(v); }
  };

  // Int max := 0
  public long max(fan.fwt.ProgressBar self) { return max.get(); }
  public void max(fan.fwt.ProgressBar self, long v) { max.set(v); }
  public final Prop.IntProp max = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ProgressBar)w).getMaximum(); }
    public void set(Widget w, int v) { ((ProgressBar)w).setMaximum(v); }
  };

}