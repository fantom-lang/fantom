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
** CenterPane lays out content in three sections: left,center,right.
** The left and right widget is layed out using their prefSize,
** while the center widget is always centered in the panes bounds
** regardless of the size of the left and right widget.
**
@NoDoc
@Js
class CenterPane : Pane
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** Left widget is laid out with preferred width.
  **
  Widget? left  { set { remove(&left).add(it); &left = it } }

  **
  ** Center widget gets centered in remaining space in the center.
  **
  Widget? center { set { remove(&center).add(it); &center = it } }

  **
  ** Right widget is laid out with preferred width.
  **
  Widget? right { set { remove(&right).add(it); &right = it } }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    left   := pref(this.left)
    center := pref(this.center)
    right  := pref(this.right)

    w := (left.w + center.w + right.w)
    h := left.h.max(center.h).max(right.h)
    return Size(w, h)
  }

  private Size pref(Widget? w)
  {
    return w == null || !w.visible ? Size.defVal : w.prefSize(Hints.defVal)
  }

  override Void onLayout()
  {
    w := size.w
    h := size.h

    left := this.left
    if (left != null)
    {
      pref := left.prefSize(Hints(null, h))
      left.bounds = Rect(0, (h-pref.h)/2, pref.w, pref.h)
    }

    center := this.center
    if (center != null)
    {
      pref := center.prefSize(Hints(null, h))
      center.bounds = Rect((w-pref.w)/2, (h-pref.h)/2, pref.w, pref.h)
    }

    right := this.right
    if (right != null)
    {
      pref := right.prefSize(Hints(null, h))
      right.bounds = Rect(w-pref.w, (h-pref.h)/2, pref.w, pref.h)
    }
  }

}