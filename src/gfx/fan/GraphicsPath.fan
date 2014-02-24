//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Feb 14  Brian Frank  Creation
//

**
** GraphicsPath is used to path complex shapes for
** stroking, filling, and clipping.
**
@Js
mixin GraphicsPath
{

  **
  ** Stroke the the current path with the current brush and pen.
  ** This call terminates the current pathing operation.
  **
  abstract This draw()

  **
  ** Fill the current path with current brush.
  ** This call terminates the current pathing operation.
  **
  abstract This fill()

  **
  ** Intersect the current clipping shape with this path.
  ** This call terminates the current pathing operation.
  **
  abstract This clip()

  **
  ** Move the current point without creating a line.
  **
  abstract This moveTo(Int x, Int y)

  **
  ** Add a line to the path from current point to given point.
  **
  abstract This lineTo(Int x, Int y)

  **
  ** Add a Bézier curve to the path.  The cp1 and cp2 parameters specify
  ** the first and second control points; x and y specify the end point.
  **
  abstract This curveTo(Int cp1x, Int cp1y, Int cp2x, Int cp2y, Int x, Int y)

  **
  ** Close the path by add a line from current point back to starting point.
  **
  abstract This close()

}