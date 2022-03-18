//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

**
** Paint models the color, image, or pattern used to stroke or fill a shape.
** Currently there is only one implementation: `Color`.
**
@Js
const mixin Paint
{
  ** Is this solid color paint
  abstract Bool isColorPaint()

  ** Return as solid Color
  abstract Color asColorPaint()
}