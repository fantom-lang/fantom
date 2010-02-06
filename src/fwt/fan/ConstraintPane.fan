//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 08  Brian Frank  Creation
//

using gfx

**
** ConstraintPane is used to constrain the preferred width
** and height of its content widget.
**
@Js
@Serializable
class ConstraintPane : ContentPane
{

  ** Minimum width or null to use pref width of content
  Int? minw := null

  ** Minimum height null to use pref height of content
  Int? minh := null

  ** Maximum width or null to use pref width of content.
  Int? maxw := null

  ** Maximum width or null to use pref height of content.
  Int? maxh := null

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    if (!visible) return Size.defVal

    pref := content.prefSize(hints)

    w := pref.w
    if (minw != null) w = w.max(minw)
    if (maxw != null) w = w.min(maxw)

    h := pref.h
    if (minh != null) h = h.max(minh)
    if (maxh != null) h = h.min(maxh)

    return Size(w, h)
  }

}