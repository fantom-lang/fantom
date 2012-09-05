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
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.Widget;

public class TablePeer
  extends WidgetPeer
  implements SelectionListener
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
    if (self.multi)
      style |= SWT.MULTI;
    else
      style |= SWT.SINGLE;
    if (self.border)  style |= SWT.BORDER;

    Table t = new Table((Composite)parent, style);
    t.addListener(SWT.SetData, this);
    t.addListener(SWT.MenuDetect, this);
    t.addSelectionListener(this);
    t.setMenu(new Menu(t));

    ScrollBar hbar = t.getHorizontalBar();
    ScrollBar vbar = t.getVerticalBar();
    if (hbar != null) ((ScrollBarPeer)self.hbar().peer).attachToScrollable(t, hbar);
    if (vbar != null) ((ScrollBarPeer)self.vbar().peer).attachToScrollable(t, vbar);

    this.control = t;
    rebuild();
    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Bool headerVisible := true
  public boolean headerVisible(fan.fwt.Table self) { return headerVisible.get(); }
  public void headerVisible(fan.fwt.Table self, boolean v) { headerVisible.set(v); }
  public final Prop.BoolProp headerVisible = new Prop.BoolProp(this, true)
  {
    public boolean get(Widget w) { return ((Table)w).getHeaderVisible(); }
    public void set(Widget w, boolean v) { ((Table)w).setHeaderVisible(v); }
  };

  // Int[] selected
  public List selected(fan.fwt.Table self) { return view().rowsViewToModel(selected.get()); }
  public void selected(fan.fwt.Table self, List v) { selected.set(view().rowsModelToView(v)); }
  public final Prop.IntsProp selected = new Prop.IntsProp(this)
  {
    public int[] get(Widget w) { return ((Table)w).getSelectionIndices(); }
    public void set(Widget w, int[] v) { ((Table)w).setSelection(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Native Methods
//////////////////////////////////////////////////////////////////////////

  public void refreshRows(fan.fwt.Table self, List indices)
  {
    Table c = (Table)this.control;
    if (c == null) return;

    indices = view().rowsModelToView(indices);
    c.clear(indices.toInts());
  }

  public void refreshAll(fan.fwt.Table self)
  {
    Table c = (Table)this.control;
    if (c == null) return;

    // remove all all columns
    while (c.getColumnCount() > 0)
    {
      try { c.getColumns()[0].dispose(); }
      catch (Exception e) { e.printStackTrace(); }
    }

    // remove all rows
    c.removeAll();

    // rebuild table from model
    rebuild();
    c.clearAll();
  }

  public Long rowAt(fan.fwt.Table self, fan.gfx.Point pos)
  {
    Table c = (Table)this.control;
    if (c == null) return null;

    TableItem item = (TableItem)c.getItem(point(pos));
    if (item == null) return null;

    int index = c.indexOf(item);
    if (index < 0) return null;

    return Long.valueOf(view().rowViewToModel(index));
  }

  public Long colAt(fan.fwt.Table self, fan.gfx.Point fanPos)
  {
    Table c = (Table)this.control;
    if (c == null) return null;

    Point swtPos = point(fanPos);
    TableItem item = (TableItem)c.getItem(swtPos);
    if (item == null) return null;

    for (int i=0; i<c.getColumnCount(); ++i)
    {
      if (item.getBounds(i).contains(swtPos))
        return Long.valueOf(view().colViewToModel(i));
    }

    return null;
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
      default:              super.handleEvent(event); break;
    }
  }

  private void handleSetData(Event event)
  {
    TableModel model = view();

    Fwt fwt = Fwt.get();
    TableItem item = (TableItem)event.item;

    long row = event.index;
    if (row >= model.numRows()) return;

    int numCols = (int)model.numCols();
    for (int i=0; i<numCols; ++i)
    {
      // Should we decide to allow embedding controls
      //fan.fwt.Widget w = model.widget(col, row);
      //this.self.add(w);
      //TableEditor editor = new TableEditor((Table)this.control);
      //editor.grabHorizontal = true;
      //editor.setEditor((Control)w.peer.control, item, i);

      long col = i;
      item.setText(i, model.text(col, row));
      item.setImage(i, fwt.image(model.image(col, row)));
      item.setFont(i, fwt.font(model.font(col, row)));
      item.setForeground(i, fwt.color(model.fg(col, row)));
      item.setBackground(i, fwt.color(model.bg(col, row)));
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
    Point ctrlPos = table.toControl(event.x, event.y);
    TableItem item = table.getItem(ctrlPos);
    final fan.fwt.Table self = (fan.fwt.Table)this.self;

    fan.fwt.Event fe = event(EventId.popup);
    fe.pos = point(ctrlPos);
    if (item != null) fe.index = selectedIndex();
    self.onPopup().fire(fe);

    // we don't use the event menu - that is just a dummy
    // menu to hook into SWT's painful popup eventing;
    // if the event provided a fwt::Menu then open it async
    final fan.fwt.Menu popup = fe.popup();
    final fan.gfx.Point pos = fan.gfx.Point.make(
      event.x-self.posOnDisplay().x,
      event.y-self.posOnDisplay().y);
    if (popup != null)
    {
      Fwt.get().display.asyncExec(new Runnable()
      {
        public void run() { popup.open(self, pos); }
      });
    }
  }

  public void rebuild()
  {
    // TODO: need to figure out how to sync
    Table table = (Table)this.control;

    // get view of model
    TableView model = view();

    // build columns
    int numCols = (int)model.numCols();
    for (int i=0; i<numCols; ++i)
    {
      long col = i;
      Long pw = model.prefWidth(col);
      TableColumn tc = new TableColumn(table, style(model.halign(col)));
      tc.addListener(SWT.Selection, sortListener);
      tc.setText(model.header(col));
      tc.setWidth(pw == null ? 100 : pw.intValue());
    }

    // rows
    table.setItemCount((int)model.numRows());
  }

//////////////////////////////////////////////////////////////////////////
// Sorting
//////////////////////////////////////////////////////////////////////////

  public void sort(fan.fwt.Table self, Long col, SortMode mode)
  {
    // update view
    self.view().sort(col, mode);

    // update SWT control
    Table table = (Table)this.control;
    if (table != null)
    {
      if (col != null)
      {
        long modelIndex = col.longValue();
        long viewIndex = view().colModelToView(modelIndex);
        table.setSortColumn(table.getColumn((int)viewIndex));
      }
      table.setSortDirection(mode == SortMode.up ? SWT.UP : SWT.DOWN);
      refreshAll(self);
    }
  }

  public void sortEvent(Event e)
  {
    Table table = (Table)this.control;
    final fan.fwt.Table self = (fan.fwt.Table)this.self;

    // map selected column to an index; can't find a freaking
    // way to easily map TableColumn to an index
    TableColumn col = (TableColumn)e.widget;
    Long sortCol = null;
    for (int i=0; i<table.getColumnCount(); ++i)
      if (table.getColumn(i) == col) { sortCol = Long.valueOf(view().colViewToModel(i)); break; }

    // figure out sorting up or down
    SortMode sortMode = SortMode.up;
    if (sortCol == self.view().sortCol())
      sortMode = self.view().sortMode().toggle();

    // do it
    sort(self, sortCol, sortMode);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Long selectedIndex()
  {
    int i = ((Table)control).getSelectionIndex();
    if (i < 0) return null;
    return Long.valueOf(view().rowViewToModel(i));
  }

  public TableView view()
  {
    return ((fan.fwt.Table)this.self).view();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  int curNumCol = -1;
  Listener sortListener = new Listener() { public void handleEvent(Event e) { sortEvent(e); } };
}