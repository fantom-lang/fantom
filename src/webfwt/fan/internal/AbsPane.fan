//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Aug 10  Andy Frank  Creation
//

using fwt
using gfx

**
** AbsPane lays out widgets using absolute positioning.
**
@NoDoc
@Js
// TODO: leave as internal until needed
internal class AbsPane : Pane
{
  new make() {}

  override Size prefSize(Hints hints := Hints.defVal)
  {
    w := 0
    h := 0

    children.each |kid|
    {
      w = w.max(kid.pos.x + kid.size.w)
      h = h.max(kid.pos.y + kid.size.h)
    }

    return Size(w,h)
  }

  override Void onLayout() {}

}

