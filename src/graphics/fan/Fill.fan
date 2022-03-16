//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

**
** Fill models the color, image, or pattern used to fill a shape.
** Currently there is only one implementation: `Color`.
**
@Js
const mixin Fill
{
  ** Is this solid color fill
  abstract Bool isColorFill()

  ** Return as solid Color
  abstract Color asColorFill()
}