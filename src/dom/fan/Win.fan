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
class Win
{

  **
  ** Return the current window instance.
  **
  static native Win cur()

  **
  ** Private ctor.
  **
  private new make() {}

  **
  ** Display a modal message box with the given text.
  **
  native Void alert(Obj obj)

  **
  ** Get the Uri for this window.
  **
  native Uri uri()

  **
  ** Hyperlink to the given Uri in this window.
  **
  native Void hyperlink(Uri uri)

}