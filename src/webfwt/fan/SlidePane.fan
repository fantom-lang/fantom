//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Sep 10  Andy Frank  Creation
//

using gfx
using fwt

**
** SlidePane slides content into view.
**
@NoDoc
@Js
class SlidePane : Pane
{

  ** PrefSize is maximum size of all children.
  override Size prefSize(Hints hints := Hints.defVal)
  {
    pw := 0
    ph := 0
    children.each |kid|
    {
      p := kid.prefSize(hints)
      pw = pw.max(p.w)
      ph = ph.max(p.h)
    }
    return Size(pw,ph)
  }

  ** Layout widgets.
  override Void onLayout()
  {
    x := 0
    children.each |kid|
    {
      kid.bounds = Rect(x, 0, size.w, size.h)
      x += size.w
    }
  }

  ** Index of widget currently in view.
  Int cur := 0

  private native Void dummy() // force native

}