//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 May 10  Andy Frank  Creation
//

using gfx
using fwt

**
** FixedPane assigns a fixed width and/or height to a content widget.
**
@NoDoc
@Js
class FixedPane : ContentPane
{
  ** Fixed width for content, or null for preferred width.
  Int? fixw := null

  ** Fixed height for content, or null for preferred width.
  Int? fixh := null

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    if (fixw != null && fixh != null) return Size(fixw, fixh)
    pref := content.prefSize
    pw := fixw ?: pref.w
    ph := fixh ?: pref.h
    return Size(pw, ph)
  }

  override Void onLayout()
  {
    pref := content.prefSize
    defw := size.w.min(pref.w)
    defh := size.h.min(pref.h)
    content.bounds = Rect(0, 0, fixw ?: defw, fixh ?: defh)
  }
}