//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using gfx

**
** Window is the base class for widgets which represent
** top level windows.
**
@Js
@Serializable
class Window : ContentPane
{
  **
  ** Callback function when window is opended.
  **
  ** Event id fired:
  **  - `EventId.open`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onOpen() { EventListeners() }

  **
  ** Callback function when window is closed.  Consume
  ** the event to prevent the window from closing.
  **
  ** Event id fired:
  **  - `EventId.close`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onClose() { EventListeners() }

  **
  ** Callback function when window becomes the active window
  ** on the desktop with focus.
  **
  ** Event id fired:
  **  - `EventId.active`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onActive() { EventListeners() }

  **
  ** Callback function when window becomes an inactive window
  ** on the desktop and loses focus.
  **
  ** Event id fired:
  **  - `EventId.inactive`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onInactive() { EventListeners() }

  **
  ** Callback function when window is iconified to the taskbar.
  **
  ** Event id fired:
  **  - `EventId.iconified`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onIconified() { EventListeners() }

  **
  ** Callback function when window is deiconified from the taskbar.
  **
  ** Event id fired:
  **  - `EventId.iconified`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onDeiconified() { EventListeners() }

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
  ** Show all normal window decorations, such as the titlebar, and
  ** frame border.  If false, only the window content will be visible.
  ** Defaults to true. This field cannot be changed once the window is
  ** constructed.
  **
  const Bool showTrim := true

  **
  ** Child menu bar widget if top level frame.
  **
  Menu? menuBar { set { remove(&menuBar); doAdd(it); &menuBar = it} }

  **
  ** Icon if window is a frame.
  **
  native Image? icon

  **
  ** Title string if window is a frame.  Defaults to "".
  **
  native Str title

  **
  ** Construct the window with an option parent window.
  **
  new make(Window? parent := null, |This|? f := null)
  {
    if (parent != null) setParent(parent)
    if (f != null) f(this)
  }

  **
  ** Open the window.  If this is a dialog, then return result
  ** passed to the `close` method (typically the Command).  Return
  ** null if canceled or closed without a result.
  **
  ** If the windows has not had its size explicitly set, then it
  ** is packed to use its preferred size.  If the position is
  ** not explicitly set, then the windows is centered over its
  ** parent window (or primary monitor if no parent).
  **
  virtual native Obj? open()

  **
  ** Close the window.
  **
  virtual native Void close(Obj? result := null)

  **
  ** Set this Window to be the active window for the application.
  **
  native Void activate()

  ** Back-door hook until we officially support drag and drop.
  ** See WindowPeer.java for details
  @NoDoc |Obj data|? onDrop

  ** Sets overlay text on dock icon for OSX.  Use empty string to
  ** clear text.
  **
  ** TODO FIXIT:
  **  - Should get moved to "FwtApp" when ready
  **  - Any better names?
  **  - Add a clearOverlayText method?
  @NoDoc native Void setOverlayText(Str text)

}