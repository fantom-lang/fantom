//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jul 08  Brian Frank  Creation
//

**
** Tree displays a hierarchy of tree nodes which can be
** expanded and collapsed.
**
class Tree : Widget
{

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
  @transient readonly EventListeners onAction := EventListeners()

  **
  ** Draw a border around the widget.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

  **
  ** Backing data model of tree.
  **
  TreeModel model

  **
  ** Update the entire tree's contents from the model.
  **
  native Void updateAll()

}

**************************************************************************
** TreeModel
**************************************************************************

**
** TreeModel models the data of a tree widget.
**
mixin TreeModel
{

  **
  ** Get root nodes.
  **
  abstract Obj[] roots()

  **
  ** Get the text to display for specified node.
  ** Default is 'node.toStr'.
  **
  virtual Str text(Obj node) { return node.toStr }

  **
  ** Get the image to display for specified node or null.
  **
  virtual Image image(Obj node) { return null }

  **
  ** Return if this has or might have children.  This
  ** is an optimization to display an expansion control
  ** without actually loading all the children.  The
  ** default returns '!children.isEmpty'.
  **
  virtual Bool hasChildren(Obj node) { return !children(node).isEmpty }

  **
  ** Get the children of the specified node.  If no
  ** children return null or the empty list.
  ** Default returns null.
  **
  virtual Obj[] children(Obj node) { return null }

}