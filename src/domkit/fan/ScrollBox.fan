//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 2014  Andy Frank  Creation
//

using dom

**
** ScrollBox displays content in a scrollable viewport.
**
@Js class ScrollBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-ScrollBox").addClass("domkit-border")
    this.onEvent("scroll", false) |e| { fireScroll(e) }
  }

  ** Callback when box is scrolled.
  Void onScroll(|This| f) { this.cbScroll = f }

  private Void fireScroll(Event e) { cbScroll?.call(this) }
  private Func? cbScroll := null
}