//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** TreeList displays a tree-style list.
**
@Js
class TreeList : WebList
{
  ** Return true to use stripe odd/even row backgrounds.
  @NoDoc
  virtual Bool zebraStripe() { false }

  ** Return true if this item should be treated as group heading.
  virtual Bool isHeading(Obj item) { false }

  ** Get display text for this item.
  virtual Str text(Obj item) { item.toStr }

  ** Get font used for item, or null for default.
  @NoDoc
  virtual Font? font(Obj item) { null }

  ** Get the icon for this item.
  virtual Image? icon(Obj item, Bool selected) { null }

  ** Get the size of the images returned in `icon`.
  virtual Size iconSize() { Size(16,16) }

  ** Get the depth for this item.
  virtual Int depth(Obj item) { 0 }

  ** Get the auxiliary text for this item, or null for none.
  virtual Str? aux(Obj item) { null }

  ** Get the style used to render aux text.
  **  - "def": default style
  **  - "pill": pill capsule style
  virtual Str auxStyle() { "def" }

  ** Get aux icon.  The aux icon size may not exceed `iconSize`.
  virtual Image? auxIcon(Obj item, Bool selected) { null }

  // force native peer
  private native Void dummy()
}

