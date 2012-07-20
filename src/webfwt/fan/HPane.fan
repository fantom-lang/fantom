//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Sep 10  Andy Frank  Creation
//

using fwt
using gfx

**
** HPane lays out widgets horizontally using the same height
** and the preferred width.
**
@NoDoc
@Js
class HPane : Pane
{
  ** Configure where children are aligned when pane contains
  ** additional extra horizontal space. If set to 'Halign.fill'
  ** children are sized evenly to fit pane width.
  Halign halign := Halign.left

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pw := 0
    ph := 0

    children.each |kid|
    {
      pref := kid.prefSize
      pw += pref.w
      ph = ph.max(pref.h)
    }

    return Size(pw, ph)
  }

  override Void onLayout()
  {
    h := size.h
    x := 0

    if (halign == Halign.fill)
    {
      // fill space
      w := size.w / children.size
      children.each |kid,i|
      {
        if (i == children.size-1) w = size.w-x
        kid.bounds = Rect(x, 0, w, h)
        x += w
      }
    }
    else
    {
      // use pref size
      children.each |kid|
      {
        p := kid.prefSize
        kid.bounds = Rect(x, 0, p.w, h)
        x += p.w
      }
    }
  }

}