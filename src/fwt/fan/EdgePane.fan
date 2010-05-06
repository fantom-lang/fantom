//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** EdgePane is a container which lays out four children along
** the four edges and one child in the center.  The top and
** bottom edges are laid out with their preferred height.  Children
** on the left or right edges are laid out with with their preferred
** width.  Any remaining space is given to the center component.
**
@Js
@Serializable
class EdgePane : Pane
{

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** Top widget is laid out with preferred height.
  **
  Widget? top { set { remove(&top).add(it); &top = it } }

  **
  ** Bottom widget is laid out with preferred height.
  **
  Widget? bottom { set { remove(&bottom).add(it); &bottom = it } }

  **
  ** Left widget is laid out with preferred width.
  **
  Widget? left  { set { remove(&left).add(it); &left = it } }

  **
  ** Right widget is laid out with preferred width.
  **
  Widget? right { set { remove(&right).add(it); &right = it } }

  **
  ** Center widget gets any remaining space in the center.
  **
  Widget? center { set { remove(&center).add(it); &center = it } }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    top    := pref(this.top)
    bottom := pref(this.bottom)
    left   := pref(this.left)
    right  := pref(this.right)
    center := pref(this.center)

    w := (left.w + center.w + right.w).max(top.w).max(bottom.w)
    h := top.h + bottom.h + (left.h.max(center.h).max(right.h))
    return Size(w, h)
  }

  private Size pref(Widget? w)
  {
    return w == null || !w.visible ? Size.defVal : w.prefSize(Hints.defVal)
  }

  override Void onLayout()
  {
    s := size
    x := 0; y := 0; w := s.w; h := s.h

    top := this.top
    if (top != null)
    {
      prefh := top.prefSize(Hints(w, null)).h
      top.bounds = Rect(x, y, w, prefh)
      y += prefh; h -= prefh
    }

    bottom := this.bottom
    if (bottom != null)
    {
      prefh := bottom.prefSize(Hints(w, null)).h
      bottom.bounds = Rect(x, y+h-prefh, w, prefh)
      h -= prefh
    }

    left := this.left
    if (left != null)
    {
      prefw := left.prefSize(Hints(null, h)).w
      left.bounds = Rect(x, y, prefw, h)
      x += prefw; w -= prefw
    }

    right := this.right
    if (right != null)
    {
      prefw := right.prefSize(Hints(null, h)).w
      right.bounds = Rect(x+w-prefw, y, prefw, h)
      w -= prefw
    }

    center := this.center
    if (center != null)
      center.bounds = Rect(x, y, w, h)
  }

}