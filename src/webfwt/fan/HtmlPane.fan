//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec May 09  Andy Frank  Creation
//

using gfx
using fwt

**
** HtmlPane displays a HTML fragment inside a fwt::Widget.
**
@Js
class HtmlPane : Pane
{

  **
  ** The width in pixels of the HTML content.
  **
  Int width := 100

  **
  ** The HTML fragment to display.
  **
  native Str html

  override native Size prefSize(Hints hints := Hints.defVal)
  override Void onLayout() {}

}

