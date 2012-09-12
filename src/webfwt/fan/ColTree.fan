//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Feb 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** ColTree visualizes a TreeModel as a series of columns.
**
@NoDoc
@Js
class ColTree : ContentPane
{
  ** Constructor.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    this.lists    = [,]
    this.listPane = ColListPane(this)
    this.scroll   = WebScrollPane
    {
      bg = Color("#eee")
      hpolicy = WebScrollPane.auto
      vpolicy = WebScrollPane.off
      listPane,
    }
    this.content = scroll
    refreshAll
  }

  ** Backing data model of tree.
  TreeModel model := TreeModel()

  **
  ** Show column headers.  To specify column headers, implement
  ** a 'header' method on your TreeModel, where the return type
  ** can be a Str# or Widget#:
  **
  **   Obj header(Obj node)
  **
  Bool headerVisible := false

  ** Width of each column in pixels.
  Int colw := 200

  ** Update the entire tree's contents from the model.
  Void refreshAll()
  {
    lists.clear
    lists.add(ColList(this, model.roots))

    listPane.removeAll
    listPane.add(lists.first)
    relayout
  }

  ** Update the specified node from the model.
  Void refreshNode(Obj node)
  {
    // TODO FIXIT
    setExpanded(node, true)
  }

  ** Get list of selected path in widget.
  Obj[] path()
  {
    if (lists.size <= 1) return [,]
    return lists[0..-2].map |x| { x.selected }
  }

  ** Set the expanded state for this node.
  Void setExpanded(Obj node, Bool expanded)
  {
    if (!expanded) return
    if (!model.hasChildren(node)) return

    // check if we need to rollback
    index := lists.findIndex |l| { l.items.contains(node) }
    diff  := lists.size-1 - index
    while (diff > 0)
    {
      listPane.remove(lists.removeAt(-1))
      diff--
    }

    // make sure item is selected
    lists[index].select(node)

    // add new list
    kids := model.children(node)
    list := ColList(this, kids)
    lists.add(list)
    listPane.add(list)
    scroll.relayout
    scroll.scrollToRight
    onExpanded.fire(Event { data=node; widget=this })
  }

  **
  ** Callback when a node's expanded state changes.
  **
  ** Event fields:
  **   - Event.data: node object that was expanded.
  **
  once EventListeners onExpanded() { EventListeners() }

  **
  ** Callback when selected nodes change.
  **
  ** Event id fired:
  **   - EventId.select
  **
  ** Event fields:
  **   - Event.data: the primary selection node object.
  **
  once EventListeners onSelect() { EventListeners() }

  ** Fire onSelect event.
  internal Void fireSelect(Obj node)
  {
    onSelect.fire(Event { id=EventId.select; data=node })
  }

  private ColList[] lists
  private ColListPane? listPane
  private WebScrollPane scroll
}

**************************************************************************
** ColListPane
**************************************************************************
@Js
internal class ColListPane : Pane
{
  new make(ColTree tree) { this.tree = tree }
  override Size prefSize(Hints hints := Hints.defVal)
  {
    sz := children.size
    pw := sz * tree.colw - (sz-1) - 2
    return Size(pw, 200)
  }
  override Void onLayout()
  {
    x := -1
    y := -1
    h := size.h+2
    children.each |kid|
    {
      kid.bounds = Rect(x, y, tree.colw, h)
      x += tree.colw-1
    }
  }
  private ColTree tree
}

**************************************************************************
** ColList
**************************************************************************
@Js
internal class ColList : EdgePane
{
  new make(ColTree tree, Obj[] items)
  {
    this.tree    = tree
    this.items   = items
    this.webList = ColWebList(tree, items)
    if (tree.headerVisible) this.top = makeHeader
    this.center = webList
  }

  Obj[] items
  Obj? selected() { webList.selected.first }

  Void select(Obj node) { webList.selected = [node] }

  private Widget makeHeader()
  {
    try
    {
      h := items.isEmpty ? "" : tree.model->header(items.first)
      if (h is Widget) return h
      else if (h is Str)
      {
        return BorderPane
        {
          bg = labelBg
          insets = labelPad
          WebLabel
          {
            text = ((Str)h).upper
            fg = labelFg
            font = Desktop.sysFontSmall.toBold
            style = ["text-shadow":"#fff 0px 1px 1px"]
          },
        }
      }
    }
    catch (Err err) { err.trace }
    return BorderPane
    {
      bg = labelBg
      insets = labelPad
      Label { font=Desktop.sysFontSmall.toBold },
    }
  }

  private static const Insets labelPad := Insets(6)
  private static const Color labelBg := Color("#eee")
  private static const Color labelFg := Color("#666")

  private ColTree tree
  private ColWebList webList
}

**************************************************************************
** ColWebList
**************************************************************************
@Js
internal class ColWebList : WebList
{
  new make(ColTree tree, Obj[] items)
  {
    this.tree   = tree
    this.items  = items
    this.onSelect.add |e|
    {
      tree.setExpanded(e.data, true)
      tree.fireSelect(e.data)
    }
  }

  // force native peer
  private native Void dummy()

  private ColTree tree
}