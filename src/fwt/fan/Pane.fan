//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

**
** Pane is a container widget responsible for the layout
** of its children.  Custom panes should:
**   1. Override prefSize to compute their preferred size
**   2. Override onLayout to set the bounds of all their children
**
abstract class Pane : Widget
{

  // to force native peer
  private native Void dummyPane()

}