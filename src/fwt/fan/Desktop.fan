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
@Js
class Desktop
{
  **
  ** Set the application name for this FWT instance.  This must
  ** be configured before any FWT objects are created.
  **
  ** TODO: potentially move this into new FwtApp class, also
  **   want to handle how closing all windows works on OS X
  **
  @NoDoc static native Void appName(Str name)

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
  static native Void callAsync(|->| f)

  **
  ** Call the specified function on the UI thread's event loop
  ** after a timer period has expired.  If this call is being made
  ** on a thread which is not the UI thread, then the function
  ** must be immutable.  If on the UI thread, then it is ok for
  ** the function to be mutable.
  **
  static native Void callLater(Duration delay, |->| f)

//////////////////////////////////////////////////////////////////////////
// Dispose
//////////////////////////////////////////////////////////////////////////

  **
  ** Free any operating system resources used by the color.
  **
  static native Void disposeColor(Color c)

  **
  ** Free any operating system resources used by the font.
  **
  static native Void disposeFont(Font f)

  **
  ** Free any operating system resources used by the image.
  **
  static native Void disposeImage(Image i)

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the default system font. The system font is used for
  ** text in menus, dialogs, and full-size controls.
  **
  static native Font sysFont()

  **
  ** Get the default small system font. The small font is used
  ** for informative text, column headings in tables, help tags,
  ** and for small controls.
  **
  static native Font sysFontSmall()

  **
  ** Get the default view system font. The view font is used in
  ** controls like Tree and Table.
  **
  static native Font sysFontView()

  **
  ** Get the default system mono-spaced font.
  **
  static native Font sysFontMonospace()

//////////////////////////////////////////////////////////////////////////
// System Colors
//////////////////////////////////////////////////////////////////////////

  ** System color for dark shadow on widgets
  static native Color sysDarkShadow()
  ** System color for normal shadow on widgets
  static native Color sysNormShadow()
  ** System color for light shadow on widgets
  static native Color sysLightShadow()
  ** System color for highlight shadow on widgets
  static native Color sysHighlightShadow()
  ** System color for foreground and text on widgets
  static native Color sysFg()
  ** System color for background on widgets
  static native Color sysBg()
  ** System color for borders on widgets
  static native Color sysBorder()

  ** System color for list text.
  static native Color sysListFg()
  ** System color for list background.
  static native Color sysListBg()
  ** System color for list selection text.
  static native Color sysListSelFg()
  ** System color for list selection background.
  static native Color sysListSelBg()

}