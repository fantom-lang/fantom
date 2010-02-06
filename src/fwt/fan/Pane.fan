//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** Pane is a container widget responsible for the layout
** of its children.  Custom panes should:
**   1. Override prefSize to compute their preferred size
**   2. Override onLayout to set the bounds of all their children
**
** See [pod doc]`pod-doc#panes` for details.
**
@Js
abstract class Pane : Widget
{

  **
  ** Compute the preferred size of this widget.  The hints indicate
  ** constraints the widget should consider in its calculations.
  ** If no constraints are known for width, then 'hints.w' will be
  ** null.  If no constraints are known for height, then 'hints.h'
  ** will be null.
  **
  override abstract Size prefSize(Hints hints := Hints.defVal)

  **
  ** Handle the layout event by setting the bounds on all children.
  **
  abstract Void onLayout()


  // to force native peer
  private native Void dummyPane()

}