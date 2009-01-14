//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

**
** Window models the DOM window object.
**
@javascript
class Window
{

  **
  ** Private ctor.
  **
  private new make() {}

  **
  ** Display a modal message box with the given text.
  **
  static Void alert(Str str) {}

  **
  ** Get the URI for this window.
  **
  static Str uri() { return "" }

  **
  ** Hyperlink to the given URI in this window.
  **
  static Void hyperlink(Str uri) {}

}