//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** TabPane is a container used organize a set of [Tabs]`Tab`.
**
class TabPane : Widget
{
  override This add(Widget kid)
  {
    if (kid isnot Tab)
      throw ArgErr("Child of TabPane must be Tab, not $kid.type")
    super.add(kid)
    return this
  }

  // to force native peer
  private native Void dummyTabPane()

}

**************************************************************************
** Tab
**************************************************************************

**
** Tab is the child widget of a `TabPane`.  It is used to
** configure the tab's text, image, and content widget.
**
class Tab : Widget
{

  **
  ** Text of the tab's label. Defaults to "".
  **
  native Str text

  **
  ** Image to display on tab. Defaults to null.
  **
  native Image image

}