//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 09  Andy Frank  Creation
//

using fwt
using gfx

**
** FlowPane lays out widgets in rows. Widgets are layed out consecutively
** based on their preferred size. Widgets are wrapped to the next row
** when they exceed the Pane's width. The row height will be the max
** pref size of the widgets in that row.
**
@NoDoc
@Js
class FlowPane : Pane
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  ** Gap to leave between widgets horizontally.
  Int hgap := 4

  ** Gap to leave between widgets vertically.
  Int vgap := 4

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    //w  := hints.w==0 ? Int.maxVal : hints.w
    w := Int.maxVal
    pw := 0
    ph := 0
    rh := 0 // cur row pref width
    rw := 0 // cur row pref height

    children.each |kid,i|
    {
      // widget pref size
      tw := 0
      if (i > 0) tw += hgap
      pref := kid.prefSize
      tw += pref.w

      if (rw+tw > w)
      {
        // wrap row
        pw = pw.max(rw)
        ph += rh + vgap
        rw = pref.w
        rh = pref.h
      }
      else
      {
        // accumulate
        rw += tw
        rh = rh.max(pref.h)
      }
    }

    pw = pw.max(rw)
    ph = ph + rh
    return Size(pw, ph)
  }

  override Void onLayout()
  {
    row := Widget[,]
    w   := size.w
    dx  := 0
    dy  := 0
    rh  := 0 // cur row max height

    // valign method
    valign := |Widget x, Int h|
    {
      x.pos = Point(x.pos.x, (h - x.bounds.h) / 2)
    }

    children.each |kid|
    {
      pref := kid.prefSize

      if (dx+pref.w > w)
      {
        // center vertically for this row
        row.each |r| { valign(r, rh) }

        // wrap row
        dx = 0
        dy += rh + vgap
        rh = 0
      }
      else row.add(kid)

      // set bounds
      kid.bounds = Rect(dx, dy, pref.w, pref.h)
      dx += pref.w + hgap
      rh = rh.max(pref.h)
    }

    // center vertically any leftovers
    row.each |r| { valign(r, rh) }
  }
}