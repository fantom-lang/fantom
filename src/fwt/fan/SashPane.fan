//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 08  Brian Frank  Creation
//

using gfx

**
** SashPane lays out its children in a row or column with
** a sash control between each one to allow resizing.
**
@Js
@Serializable { collection = true }
class SashPane : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Horizontal or veritical configuration.  Defaults
  ** to horizontal.  Must be set at construction time.
  **
  const Orientation orientation := Orientation.horizontal

  **
  ** Relative weights of each child as percentages.
  ** If null, then children are evenly divided.  The
  ** default is null.
  **
  native Int[]? weights

}