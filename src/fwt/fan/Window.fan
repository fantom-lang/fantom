//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

**
** Window is the base class for widgets which represent
** top level windows.
**
class Window : ContentPane
{

  **
  ** Window mode defines the modal state of the window:
  **   - modeless: no blocking of other windows
  **   - windowModal: input is blocked to parent window
  **   - appModal: input is blocked to all other windows of application
  **   - sysModal: input is blocked to all windows of all applications
  ** The default is appModel for Dialogs and modeless for all other
  ** window types.  This field cannot be changed once the window
  ** is constructed.
  **
  const WindowMode mode := this is Dialog ? WindowMode.appModal : WindowMode.modeless

  **
  ** Force window to always be on top of the desktop.  Default
  ** is false.  This field cannot be changed once the window is
  ** constructed.
  **
  const Bool alwaysOnTop := false

  **
  ** Can this window be resizable.  Default is true.  This field
  ** cannot be changed once the window is constructed.
  **
  const Bool resizable := true

  **
  ** Child menu bar widget if top level frame.
  **
  Menu menuBar { set { remove(@menuBar); Widget.super.add(val); @menuBar= val } }

  **
  ** Icon if window is a frame.
  **
  native Image icon

  **
  ** Title string if window is a frame.  Defaults to "".
  **
  native Str title

  **
  ** Construct the window with an option parent window.
  **
  new make(Window parent := null) { setParent(parent) }

  **
  ** Open the window.  If this is a dialog, then return result.
  ** If the windows hasn't had its size explicitly set, then it
  ** is packed to use its preferred size.  If the position is
  ** not explicitly set, then the windows is centered over its
  ** parent window (or primary monitor if no parent).
  **
  native Obj open()

  **
  ** Close the window.
  **
  native Void close()

}