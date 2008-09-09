//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.Widget;

public class TablePeer
  extends WidgetPeer
  implements Listener
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
    int style = SWT.VIRTUAL;
    if (self.border.val)  style |= SWT.BORDER;
    Table t = new Table((Composite)parent, style);
    t.addListener(SWT.SetData, this);
    t.addListener(SWT.DefaultSelection, this);
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

//////////////////////////////////////////////////////////////////////////
// Native Methods
//////////////////////////////////////////////////////////////////////////

  public void updateAll(fan.fwt.Table self)
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
      case SWT.SetData:          handleSetData(event); break;
      case SWT.DefaultSelection: handleDefaultSelection(event); break;
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
    }
  }

  private void handleDefaultSelection(Event event)
  {
    Table table = (Table)this.control;
    fan.fwt.Table self = (fan.fwt.Table)this.self;
    TableItem item = (TableItem)event.item;
    if (!self.onAction().isEmpty().val)
    {
      fan.fwt.Event fe = event(EventId.action);
      fe.index = Int.make(table.getSelectionIndex());
      self.onAction().fire(fe);
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
      tc.setWidth(100);
    }

    // rows
    table.setItemCount((int)model.numRows().val);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public TableModel model()
  {
    return ((fan.fwt.Table)this.self).model;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  int curNumCol = -1;
}