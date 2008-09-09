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
  ** Open the window.
  **
  native This open()

  **
  ** Close the window.
  **
  native This close()

}