//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

**
** Window models the DOM window object.
**
@js
class Window
{

  **
  ** Private ctor.
  **
  private new make() {}

  **
  ** Display a modal message box with the given text.
  **
  static native Void alert(Obj obj)

  **
  ** Get the Uri for this window.
  **
  static native Uri uri()

  **
  ** Hyperlink to the given Uri in this window.
  **
  static native Void hyperlink(Uri uri)

}