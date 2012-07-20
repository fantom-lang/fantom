//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Sep 10  Andy Frank  Creation
//

using fwt
using gfx

**
** LayerPane lays out widgets to fit bounds of Pane, layering each
** child on top of the previous, in order of 'children'.
**
@NoDoc
@Js
// TODO: leave as internal until needed
internal class LayerPane : Pane
{
  new make() {}

  override Size prefSize(Hints hints := Hints.defVal)
  {
    w := 0
    h := 0

    children.each |kid|
    {
      w = w.max(kid.size.w)
      h = h.max(kid.size.h)
    }

    return Size(w,h)
  }

  override Void onLayout()
  {
    children.each |kid|
    {
      kid.bounds = Rect(0, 0, size.w, size.h)
    }
  }

}

