//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jul 08  Brian Frank  Creation
//
package fan.fwt;

import java.util.ArrayList;
import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.events.*;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.Widget;

public class TreePeer
  extends WidgetPeer
  implements Listener, SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TreePeer make(fan.fwt.Tree self)
    throws Exception
  {
    TreePeer peer = new TreePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.Tree self = (fan.fwt.Tree)this.self;

    int style = SWT.VIRTUAL;
    if (self.multi)
      style |= SWT.MULTI;
    else
      style |= SWT.SINGLE;
    if (self.border)  style |= SWT.BORDER;

    Tree t = new Tree((Composite)parent, style);
    t.addListener(SWT.Expand, this);
    t.addListener(SWT.SetData, this);
    t.addListener(SWT.MenuDetect, this);
    t.addSelectionListener(this);
    t.setMenu(new Menu(t));

    ScrollBar hbar = t.getHorizontalBar();
    ScrollBar vbar = t.getVerticalBar();
    if (hbar != null) ((ScrollBarPeer)self.hbar().peer).attachToScrollable(t, hbar);
    if (vbar != null) ((ScrollBarPeer)self.vbar().peer).attachToScrollable(t, vbar);

    if (Fwt.isWindows())
    {
      // don't use dotted lines because they offend Andy's sense of taste
      // Fwt.osSet(t, Fwt.os("GWL_STYLE"), Fwt.osGet(t, Fwt.os("GWL_STYLE")) ^ Fwt.os("TVS_HASLINES"));
    }

    this.control = t;
    rebuild();
    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Obj[] selected
  public List selected(fan.fwt.Tree self) { return (List)selected.get(); }
  public void selected(fan.fwt.Tree self, List v) { selected.set((List)v); }
  public final Prop.Custom selected = new Prop.Custom(this)
  {
    void syncToControl() { set(val); }
    void syncFromControl() { get(); }

    Object get()
    {
      if (control == null) return val;
      val = nodes(((Tree)control).getSelection());
      return val.ro();
    }

    void set(Object v)
    {
      val = (List)v;
      if (control == null) return;
      ((Tree)control).setSelection(items(val));
    }

    List val = new List(Sys.ObjType);
  };

//////////////////////////////////////////////////////////////////////////
// Native Methods
//////////////////////////////////////////////////////////////////////////

  public void select(fan.fwt.Tree self, Object node)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    TreeItem item = item(node);
    if (item == null) return;
    c.select(item);
  }

  public void setExpanded(fan.fwt.Tree self, Object node, boolean expanded)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    TreeItem item = item(node);
    if (item == null) return;

    lazyLoadChildren(item);
    for (int i=0; i<item.getItemCount(); i++)
    {
      TreeItem child = item.getItem(i);
      if (child.getData() == null)
        setData(model.children(node).get(i), child);
    }
    item.setExpanded(expanded);
  }

  public void show(fan.fwt.Tree self, Object node)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    TreeItem item = item(node);
    if (item == null) return;
    c.showItem(item);
  }

  public void refreshAll(fan.fwt.Tree self)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    c.removeAll();
    c.setItemCount(model.roots().sz());
    c.clearAll(true);
  }

  public void refreshNode(fan.fwt.Tree self, Object node)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    TreeItem item = item(node);
    if (item == null) return;
    Data data = (Data)item.getData();
    data.children = null;

    item.removeAll();
    lazyLoadChildren(item);
    item.clearAll(true);
  }

  public Object nodeAt(fan.fwt.Tree self, fan.gfx.Point pos)
  {
    Tree c = (Tree)this.control;
    if (c == null) return null;

    TreeItem item = c.getItem(point(pos));
    if (item == null) return null;

    Data data = (Data)item.getData();
    if (data == null) return null;

    return data.node;
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void handleEvent(Event event)
  {
    switch (event.type)
    {
      case SWT.Expand:     handleExpand(event); break;
      case SWT.SetData:    handleSetData(event); break;
      case SWT.MenuDetect: handleMenuDetect(event); break;
      default: System.out.println("WARNING: TreePeer.handleEvent: " + event);
    }
  }

  private void handleExpand(Event event)
  {
    TreeModel model = model();
    if (model == null) return;

    TreeItem item = (TreeItem)event.item;
    lazyLoadChildren(item);
  }

  private void lazyLoadChildren(TreeItem item)
  {
    // in handleSetData we set the number of children to 1
    // if we might have children, but we don't actually
    // load the children until the user attempts to expand
    Data data = (Data)item.getData();
    if (data.children == null)
    {
      List kids = model().children(data.node);
      data.children = kids;
      item.setItemCount(kids.sz());
    }
  }

  private void handleSetData(Event event)
  {
    TreeModel model = model();
    if (model == null) return;

    TreeItem item = (TreeItem)event.item;
    TreeItem parentItem = item.getParentItem();

    // map the event to a node
    Object node;
    if (parentItem == null)
    {
      // if no parent item, then this is a root node
      node = model.roots().get(event.index);
    }
    else
    {
      // check that've loaded the parent's children, then lookup node
      Data parentData = (Data)parentItem.getData();
      lazyLoadChildren(parentItem);
      if (event.index >= parentData.children.sz()) return;
      node = parentData.children.get(event.index);
    }

    setData(node, item);
  }

  private void setData(Object node, TreeItem item)
  {
    TreeModel model = model();
    if (model == null) return;

    Data data = new Data();
    data.node = node;

    Fwt fwt = Fwt.get();
    item.setText(model.text(node));
    item.setImage(fwt.image(model.image(node)));
    item.setFont(fwt.font(model.font(node)));
    item.setForeground(fwt.color(model.fg(node)));
    item.setBackground(fwt.color(model.bg(node)));
    item.setData(data);

    // assume we only have one child to prevent the SWT from loading
    // the children until the node is expanded; see lazyLoadChildren
    item.setItemCount(model.hasChildren(node) ? 1 : 0);

    // post a repaint request for the full tree
    Tree tree = (Tree)this.control;
    tree.redraw();
  }

  public void widgetDefaultSelected(SelectionEvent se)
  {
    fan.fwt.Tree self = (fan.fwt.Tree)this.self;
    TreeItem item = (TreeItem)se.item;
    if (self.onAction().isEmpty())
    {
      item.setExpanded(!item.getExpanded());
    }
    else
    {
      self.onAction().fire(event(EventId.action, node(item)));
    }
  }

  public void widgetSelected(SelectionEvent se)
  {
    Tree tree = (Tree)this.control;
    fan.fwt.Tree self = (fan.fwt.Tree)this.self;
    TreeItem item = (TreeItem)se.item;
    self.onSelect().fire(event(EventId.select, node(item)));
  }

  public void handleMenuDetect(Event event)
  {
    Tree tree = (Tree)this.control;
    Point ctrlPos = tree.toControl(event.x, event.y);
    TreeItem item = tree.getItem(ctrlPos);
    final fan.fwt.Tree self = (fan.fwt.Tree)this.self;

    fan.fwt.Event fe = event(EventId.popup);
    fe.pos = point(ctrlPos);
    if (item != null) fe.data = node(item);
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
    Tree tree = (Tree)this.control;

    // get model
    TreeModel model = model();
    if (model == null) return;

    // define roots
    tree.setItemCount(model.roots().sz());
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  TreeItem[] items(List nodes)
  {
    ArrayList acc = new ArrayList(nodes.sz());
    for (int i=0; i<nodes.sz(); ++i)
    {
      TreeItem item = item(nodes.get(i));
      if (item != null) acc.add(item);
    }
    return (TreeItem[])acc.toArray(new TreeItem[acc.size()]);
  }

  TreeItem item(Object node)
  {
    TreeItem[] items = ((Tree)control).getItems();
    for (int i=0; i<items.length; ++i)
    {
      TreeItem r = item(node, items[i]);
      if (r != null) return r;
    }
    return null;
  }

  TreeItem item(Object node, TreeItem item)
  {
    Data data = (Data)item.getData();
    if (data == null) return null;
    if (data.node == node) return item;
    for (int i=0; i<item.getItemCount(); ++i)
    {
      TreeItem r = item(node, item.getItem(i));
      if (r != null) return r;
    }
    return null;
  }

  List nodes(TreeItem[] items)
  {
    List acc = new List(Sys.ObjType, items.length);
    for (int i=0; i<items.length; ++i)
      acc.add(((Data)items[i].getData()).node);
    return acc;
  }

  Object node(TreeItem item)
  {
    if (item == null) return null;
    Data data = (Data)item.getData();
    if (data == null) return null;
    return data.node;
  }

  public TreeModel model()
  {
    return ((fan.fwt.Tree)this.self).model;
  }

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  static class Data
  {
    Object node;
    List children;
  }

}