//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jul 08  Brian Frank  Creation
//

using gfx

**
** Tree displays a hierarchy of tree nodes which can be
** expanded and collapsed.
**
@Serializable
class Tree : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Callback when node is double clicked or Return/Enter
  ** key is pressed.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - `Event.data`: the `TreeModel` node object
  **
  @Transient EventListeners onAction := EventListeners() { private set }

  **
  ** Callback when selected nodes change.
  **
  ** Event id fired:
  **   - `EventId.select`
  **
  ** Event fields:
  **   - `Event.data`: the primary selection node object.
  **
  @Transient EventListeners onSelect := EventListeners() { private set }

  **
  ** Callback when user invokes a right click popup action.
  ** If the callback wishes to display a popup, then set
  ** the `Event.popup` field with menu to open.  If multiple
  ** callbacks are installed, the first one to return a nonnull
  ** popup consumes the event.
  **
  ** Event id fired:
  **   - `EventId.popup`
  **
  ** Event fields:
  **   - `Event.data`: the primary selection node object, or
  **     'null' if this is a background popup.
  **   - `Event.pos`: the mouse position of the popup.
  **
  @Transient EventListeners onPopup := EventListeners() { private set }

  **
  ** Horizontal scroll bar.
  **
  @Transient ScrollBar hbar := ScrollBar() { private set }

  **
  ** Vertical scroll bar.
  **
  @Transient ScrollBar vbar := ScrollBar() { private set }

  **
  ** Background color of tree, or null for platform default.
  **
  const Color? bg := null

  **
  ** Draw a border around the widget.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

  **
  ** True to enable multi-node selection, false for single
  ** node selection.  Default is false.  This field cannot
  ** be changed once the widget is constructed.
  **
  const Bool multi := false

  **
  ** Backing data model of tree.
  **
  TreeModel model := TreeModel()

  **
  ** Select the given item in the tree.
  **
  native Void select(Obj node)

  **
  ** Get and set the selected nodes.
  **
  native Obj[] selected

  **
  ** Return the expanded state for this node.
  **
  native Bool isExpanded(Obj node)

  **
  ** Set the expanded state for this node.
  **
  native Void setExpanded(Obj node, Bool expanded)

  **
  ** Shows the node. If the node is already showing in the
  ** tree, this method simply returns. Otherwise, the items
  ** are scrolled and expanded until the node is visible
  **
  native Void show(Obj node)

  **
  ** Update the entire tree's contents from the model.
  **
  native Void refreshAll()

  **
  ** Update the specified node from the model.
  **
  native Void refreshNode(Obj node)

  **
  ** Return the tree node at the specified coordinate relative
  ** to this widget.  Return null if no node at given coordinate.
  **
  native Obj? nodeAt(Point pos)

}

**************************************************************************
** TreeModel
**************************************************************************

**
** TreeModel models the data of a tree widget.
**
@Js
class TreeModel
{
  **
  ** Get root nodes.
  **
  virtual Obj[] roots() { [,] }

  **
  ** Get the text to display for specified node.
  ** Default is 'node.toStr'.
  **
  virtual Str text(Obj node) { node.toStr }

  **
  ** Get the image to display for specified node or null.
  **
  virtual Image? image(Obj node) { null }

  **
  ** Get the font for specified node or null for default.
  **
  virtual Font? font(Obj node) { null }

  **
  ** Get the foreground color for specified node or null for default.
  **
  virtual Color? fg(Obj node) { null }

  **
  ** Get the background color for specified node or null for default.
  **
  virtual Color? bg(Obj node) { null }

  **
  ** Return if this has or might have children.  This
  ** is an optimization to display an expansion control
  ** without actually loading all the children.  The
  ** default returns '!children.isEmpty'.
  **
  virtual Bool hasChildren(Obj node) { !children(node).isEmpty }

  **
  ** Get the children of the specified node.  If no children
  ** return an empty list.  Default behavior is no children.
  **
  virtual Obj[] children(Obj node) { Obj#.emptyList }

}