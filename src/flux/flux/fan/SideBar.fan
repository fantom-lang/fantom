//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** SideBar is a plugin used along side the main views.  SideBars
** are registered using the indexed prop "flux.sideBar={qname}".
**
abstract class SideBar : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the top level flux window.
  **
  Frame? frame { internal set }

  **
  ** Get this sidebar's preferred alignment which is used to
  ** determine its default position.  Valid values are:
  **   - Halign.left (default)
  **   - Halign.right
  **   - Valign.bottom
  **
  virtual Obj prefAlign() { return Halign.left }

  **
  ** Is the sidebar currently shown in the frame?
  **
  Bool showing := false { internal set }

  **
  ** Show this sidebar in the frame.
  **
  This show()
  {
    if (showing) return this
    showing=true
    frame.sideBarPane.show(this)
    content?.relayout
    return this
  }

  **
  ** Hide this sidebar in the frame.
  **
  This hide()
  {
    if (!showing) return this
    showing=false
    frame.sideBarPane.hide(this)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  **
  ** Callback when sidebar is first loaded into memory.
  ** This is the time to load persistent state.
  **
  virtual Void onLoad() {}

  **
  ** Callback when sidebar is being unloaded from memory.
  ** This is the time to save persistent state.  This is
  ** called no matter whether the sidebar is shown or hidden.
  **
  virtual Void onUnload() {}

  **
  ** Callback when sidebar is shown in the frame.
  **
  virtual Void onShow() {}

  **
  ** Callback when sidebar is hidden in the frame.
  **
  virtual Void onHide() {}

  **
  ** Callback when specified view is selected as the
  ** active tab.  This callback is invoked only if showing.
  **
  virtual Void onActive(View view) {}

  **
  ** Callback when specified view is unselected as the
  ** active tab.  This callback is invoked only if showing.
  **
  virtual Void onInactive(View view) {}

  **
  ** Callback when the frame's list of marks is updated.
  **
  virtual Void onMarks(Mark[] marks) {}

  **
  ** Callback before the current view is jumped to
  ** the specified mark.
  **
  virtual Void onGotoMark(Mark mark) {}

}

