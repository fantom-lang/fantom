//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jul 08  Brian Frank  Creation
//

using gfx

**
** InsetPane creates padding along the four edges of its content.
**
@Js
@Serializable
class InsetPane : ContentPane
{

  **
  ** Insets to leave around the edge of the content.
  ** The default is 12 pixels on all sides.
  **
  Insets insets := defInsets

  private const static Insets defInsets := Insets(12)

  **
  ** Construct with optional top, right, bottom, left insets.  If
  ** one side is not specified, that value is reflected from the
  ** opposite side:
  **
  **   InsetPane(5)     === InsetPane(5,5,5,5)
  **   InsetPane(5,6)   === InsetPane(5,6,5,6)
  **   InsetPane(5,6,7) === InsetPane(5,6,7,6)
  **
  new make(Int top := 12, Int? right := null, Int? bottom := null, Int? left := null)
  {
    if (right == null) right = top
    if (bottom == null) bottom = top
    if (left == null) left = right
    insets = Insets(top, right, bottom, left)
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    if (!visible) return Size.defVal
    insetSize := insets.toSize
    pref := content.prefSize(hints - insetSize)
    return Size(pref.w + insetSize.w, pref.h + insetSize.h)
  }

  override Void onLayout()
  {
    if (content == null) return
    content.bounds = Rect(
      insets.left,
      insets.top,
      this.size.w - insets.left - insets.right,
      this.size.h - insets.top - insets.bottom)
  }
}