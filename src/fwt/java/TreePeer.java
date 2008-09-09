//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jul 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.Widget;

public class TreePeer
  extends WidgetPeer
  implements Listener
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
    if (self.border.val)  style |= SWT.BORDER;

    Tree t = new Tree((Composite)parent, style);
    t.addListener(SWT.SetData, this);
    t.addListener(SWT.DefaultSelection, this);

    if (Env.isWindows())
    {
      // don't use dotted lines because they offend Andy's sense of taste
      Env.osSet(t, Env.os("GWL_STYLE"), Env.osGet(t, Env.os("GWL_STYLE")) ^ Env.os("TVS_HASLINES"));
    }

    this.control = t;
    rebuild();
    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Native Methods
//////////////////////////////////////////////////////////////////////////

  public void updateAll(fan.fwt.Tree self)
  {
    Tree c = (Tree)this.control;

    TreeModel model = model();
    if (model == null) return;

    c.removeAll();
    c.setItemCount(model.roots().sz());
    c.clearAll(true);
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
    TreeModel model = model();
    if (model == null) return;

    Env env = Env.get();
    TreeItem item = (TreeItem)event.item;
    TreeItem parentItem = item.getParentItem();

    // root
    Obj node;
    if (parentItem == null)
      node = model.roots().get(event.index);
    else
      node = ((Data)parentItem.getData()).children.get(event.index);

    Data data = new Data();
    data.node = node;
    data.children = model.children(node);

    List kids = model.children(node);
    item.setText(model.text(node).val);
    item.setImage(env.image(model.image(node)));
    item.setData(data);
    item.setItemCount(kids.sz());
  }

  private void handleDefaultSelection(Event event)
  {
    fan.fwt.Tree self = (fan.fwt.Tree)this.self;
    TreeItem item = (TreeItem)event.item;
    Data data = (Data)item.getData();
    if (self.onAction().isEmpty().val)
    {
      item.setExpanded(!item.getExpanded());
    }
    else
    {
      self.onAction().fire(event(EventId.action, data.node));
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

  public TreeModel model()
  {
    return ((fan.fwt.Tree)this.self).model;
  }

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  static class Data
  {
    Obj node;
    List children;
  }

}