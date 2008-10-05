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
import org.eclipse.swt.events.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;

public class TabPanePeer
  extends WidgetPeer
  implements SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TabPanePeer make(TabPane self)
    throws Exception
  {
    TabPanePeer peer = new TabPanePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    TabFolder c = new TabFolder((Composite)parent, SWT.TOP);
    this.control = c;
    c.addSelectionListener(this);
    return c;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Int selectedIndex := 0
  public Long selectedIndex(TabPane self) { return selectedIndex.get(); }
  public void selectedIndex(TabPane self, Long v) { selectedIndex.set(v); }
  public final Prop.IntProp selectedIndex = new Prop.IntProp(this, 0, true)
  {
    public int get(Widget w) { return ((TabFolder)w).getSelectionIndex(); }
    public void set(Widget w, int v) { ((TabFolder)w).setSelection(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void widgetDefaultSelected(SelectionEvent e) {} // unused

  public void widgetSelected(SelectionEvent e)
  {
    TabFolder control = (TabFolder)this.control;
    TabPane self = (TabPane)this.self;
    fan.fwt.Event fe = event(EventId.select);
    fe.index = Long.valueOf(control.getSelectionIndex());
    fe.data  = self.tabs().get(fe.index);
    self.onSelect().fire(fe);
  }
}