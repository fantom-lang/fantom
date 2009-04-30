//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//

using gfx

**
** Desktop is used to model the user's operating system,
** window manager, and display monitors.  See `Monitor`
** to query the desktop monitors.
**
class Desktop
{

  **
  ** Get the platform name: "windows", "mac"
  **
  static native Str platform()

  **
  ** Is the desktop running a version of Microsoft Windows.
  **
  static native Bool isWindows()

  **
  ** Is the desktop running a version of Apple OS X.
  **
  static native Bool isMac()

  **
  ** Get the working bounds of the entire desktop which may
  ** span multiple Monitors.  Also see `Monitor.bounds` and
  ** `Monitor.screenBounds`.
  **
  static native Rect bounds()

  **
  ** Get the current focused widget or return null.
  **
  static native Widget? focus()

  **
  ** Call the specified function on the UI thread's event loop.
  ** If this call is being made on a thread which is not the
  ** UI thread, then the function must be immutable.  If
  ** on the UI thread, then it is ok for the function to be
  ** mutable.
  **
  static native Void callAsync(|,| f)

}