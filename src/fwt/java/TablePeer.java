//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.events.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.Widget;

public class TablePeer
  extends WidgetPeer
  implements Listener, SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TablePeer make(fan.fwt.Table self)
    throws Exception
  {
    TablePeer peer = new TablePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.Table self = (fan.fwt.Table)this.self;

    int style = SWT.VIRTUAL | SWT.FULL_SELECTION;
    if (self.multi.val)
      style |= SWT.MULTI;
    else
      style |= SWT.SINGLE;
    if (self.border.val)  style |= SWT.BORDER;

    Table t = new Table((Composite)parent, style);
    t.addListener(SWT.SetData, this);
    t.addListener(SWT.MenuDetect, this);
    t.addSelectionListener(this);
    t.setMenu(new Menu(t));

    this.control = t;
    rebuild();
    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Bool headerVisible := true
  public Bool headerVisible(fan.fwt.Table self) { return headerVisible.get(); }
  public void headerVisible(fan.fwt.Table self, Bool v) { headerVisible.set(v); }
  public final Prop.BoolProp headerVisible = new Prop.BoolProp(this, true)
  {
    public boolean get(Widget w) { return ((Table)w).getHeaderVisible(); }
    public void set(Widget w, boolean v) { ((Table)w).setHeaderVisible(v); }
  };

  // Int[] selected
  public List selected(fan.fwt.Table self) { return selected.get(); }
  public void selected(fan.fwt.Table self, List v) { selected.set(v); }
  public final Prop.IntsProp selected = new Prop.IntsProp(this)
  {
    public int[] get(Widget w) { return ((Table)w).getSelectionIndices(); }
    public void set(Widget w, int[] v) { ((Table)w).select(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Native Methods
//////////////////////////////////////////////////////////////////////////

  public void refreshAll(fan.fwt.Table self)
  {
    Table c = (Table)this.control;

    TableModel model = model();
    if (model == null) return;

    c.removeAll();
    c.setItemCount((int)model.numRows().val);
    c.clearAll();
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void handleEvent(Event event)
  {
    switch (event.type)
    {
      case SWT.SetData:     handleSetData(event); break;
      case SWT.MenuDetect:  handleMenuDetect(event); break;
      default: System.out.println("WARNING: TreePeer.handleEvent: " + event);
    }
  }

  private void handleSetData(Event event)
  {
    TableModel model = model();
    if (model == null) return;

    Env env = Env.get();
    TableItem item = (TableItem)event.item;

    int numCols = (int)model.numCols().val;
    Int row = Int.make(event.index);
    for (int i=0; i<numCols; ++i)
    {
      Int col = Int.make(i);
      item.setText(i, model.text(col, row).val);
      item.setImage(i, env.image(model.image(col, row)));
      item.setFont(i, env.font(model.font(col, row)));
      item.setForeground(i, env.color(model.fg(col, row)));
      item.setBackground(i, env.color(model.bg(col, row)));
    }
  }

  public void widgetDefaultSelected(SelectionEvent se)
  {
    Table table = (Table)this.control;
    fan.fwt.Table self = (fan.fwt.Table)this.self;

    fan.fwt.Event fe = event(EventId.action);
    fe.index = selectedIndex();
    self.onAction().fire(fe);
  }

  public void widgetSelected(SelectionEvent se)
  {
    Table table = (Table)this.control;
    fan.fwt.Table self = (fan.fwt.Table)this.self;

    fan.fwt.Event fe = event(EventId.select);
    fe.index = selectedIndex();
    self.onSelect().fire(fe);
  }

  public void handleMenuDetect(Event event)
  {
    Table table = (Table)this.control;
    TableItem item = table.getItem(table.toControl(event.x, event.y));
    final fan.fwt.Table self = (fan.fwt.Table)this.self;

    fan.fwt.Event fe = event(EventId.popup);
    if (item != null) fe.index = selectedIndex();
    self.onPopup().fire(fe);

    // we don't use the event menu - that is just a dummy
    // menu to hook into SWT's painful popup eventing;
    // if the event provided a fwt::Menu then open it async
    final fan.fwt.Menu popup = fe.popup();
    if (popup != null)
    {
      Env.get().display.asyncExec(new Runnable()
      {
        public void run() { popup.open(self); }
      });
    }
  }

  public void rebuild()
  {
    // TODO: need to figure out how to sync
    Table table = (Table)this.control;

    // get model
    TableModel model = model();
    if (model == null) return;

    // build columns
    int numCols = (int)model.numCols().val;
    for (int i=0; i<numCols; ++i)
    {
      Int col = Int.make(i);
      TableColumn tc = new TableColumn(table, style(model.halign(col)));
      tc.setText(model.header(col).val);
      tc.setWidth(200);
    }

    // rows
    table.setItemCount((int)model.numRows().val);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Int selectedIndex()
  {
    int i = ((Table)control).getSelectionIndex();
    if (i < 0) return null;
    return Int.make(i);
  }

  public TableModel model()
  {
    return ((fan.fwt.Table)this.self).model;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  int curNumCol = -1;
}