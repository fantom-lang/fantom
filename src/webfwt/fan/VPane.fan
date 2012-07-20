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
** VPane lays out widgets vertically using the same width
** and the preferred height.
**
@NoDoc
@Js
class VPane : Pane
{
  ** Configure where children are aligned when pane contains
  ** additional extra vertical space. If set to 'Valign.fill'
  ** children are sized evenly to fit pane height.
  Valign valign := Valign.top

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pw := 0
    ph := 0

    children.each |kid|
    {
      pref := kid.prefSize
      pw = pw.max(pref.w)
      ph += pref.h
    }

    return Size(pw, ph)
  }

  override Void onLayout()
  {
    w := size.w
    y := 0

    if (valign == Valign.fill)
    {
      // fill space
      h := size.h / children.size
      children.each |kid,i|
      {
        if (i == children.size-1) h = size.h-y
        kid.bounds = Rect(0, y, w, h)
        y += h
      }
    }
    else
    {
      // use pref size
      children.each |kid|
      {
        p := kid.prefSize
        kid.bounds = Rect(0, y, w, p.h)
        y += p.h
      }
    }
  }

}