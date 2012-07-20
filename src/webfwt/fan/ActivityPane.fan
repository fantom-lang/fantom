//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 May 10  Andy Frank  Creation
//

using gfx
using fwt

**
** ActivityPane blocks input to a Widget while displaying an activity message.
**
@Js
class ActivityPane
{
  **
  ** Throbber image to display next to message.
  **
  Image? image := Image(`fan://webfwt/res/img/throbber-charcoal.gif`)

  **
  ** Message to display.
  **
  Str msg := "Loading"

  **
  ** Return true while pane is open.
  **
  native Bool working()

  **
  ** Open ActivityPane over given widget.
  **
  native This open(Widget parent)

  **
  ** Close pane.
  **
  native Void close()

  **
  ** Find the first open instance of ActivityPane, or null
  ** if none exist.
  **
  static native ActivityPane? find()

}