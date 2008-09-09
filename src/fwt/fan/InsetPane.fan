//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jul 08  Brian Frank  Creation
//

**
** InsetPane creates padding along the four edges of its content.
**
class InsetPane : ContentPane
{

  **
  ** Insets to leave around the edge of the content.
  ** The default is 10 pixels on all sides.
  **
  Insets insets := defInsets

  private const static Insets defInsets := Insets(10, 10, 10, 10)

  **
  ** Construct with optional top, right, bottom, left insets
  **
  new make(Int top := 10, Int right := 10, Int bottom := 10, Int left := 10)
  {
    insets = Insets(top, right, bottom, left)
  }

  override Size prefSize(Hints hints := Hints.def)
  {
    if (content == null) return Size.def
    insetSize := insets.toSize
    pref := content.prefSize(hints - insetSize)
    return Size(pref.w + insetSize.w, pref.h + insetSize.h)
  }

  override Void onLayout()
  {
    if (content == null) return
    content.bounds = Rect
    {
      x = insets.left
      y = insets.top
      w = size.w - insets.left - insets.right
      h = size.h - insets.top - insets.bottom
    }
  }
}