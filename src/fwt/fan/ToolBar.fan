//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

**
** ToolBar contains a bar of Button children.
**
class ToolBar : Widget
{

  **
  ** Horizontal or veritical configuration.  Defaults
  ** to horizontal.  Must be set at construction time.
  **
  const Orientation orientation := Orientation.horizontal

  // to force native peer
  private native Void dummyToolBar()

}