//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 08  Brian Frank  Creation
//

using gfx

**
** Monitor represents a display device like an LCD screen.
**
**
class Monitor
{

  **
  ** Get the list of monitors supported by the desktop.
  **
  static native Monitor[] list()

  **
  ** Get the primary monitor for the desktop.
  **
  static native Monitor primary()

  **
  ** Get the application working bounds of the monitor taking
  ** into account window manager chrome such as the Taskbar.
  ** Also see `screenBounds`.
  **
  native Rect bounds()

  **
  ** Get the actual bounds of the screen for this monitor in
  ** the desktop coordinate system.  Also see `bounds` to get
  ** the working bounds of the monitor taking into account window
  ** manager chrome such as the Taskbar.
  **
  native Rect screenBounds()

  **
  ** Dots per inch horizontal/vertical of this monitor.
  **
  native Size dpi()


}