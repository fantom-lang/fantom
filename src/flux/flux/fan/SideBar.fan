//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** SideBar is a plugin used along side the main views.  SideBars
** are registered in the type database via the '@fluxSideBar' facet.
**
abstract class SideBar : ContentPane
{

  **
  ** Get the top level flux window.
  **
  Frame frame { internal set }

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
  Void show()
  {
    if (showing) return
    showing=true
    frame.sideBarPane.show(this)
  }

  **
  ** Hide this sidebar in the frame.
  **
  Void hide()
  {
    if (!showing) return
    showing=false
    frame.sideBarPane.hide(this)
  }

}

