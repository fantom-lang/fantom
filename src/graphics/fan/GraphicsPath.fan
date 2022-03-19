//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

**
** GraphicsPath is used to path complex shapes for stroking,
** filling, and clipping.
**
@Js
mixin GraphicsPath
{

  ** Stroke the the current path using current stroke and paint.
  ** This call terminates the current pathing operation.
  abstract This draw()

  ** Fill the current path with current paint.
  ** This call terminates the current pathing operation.
  abstract This fill()

  ** Intersect the current clipping shape with this path.
  ** This call terminates the current pathing operation.
  abstract This clip()

  ** Move the current point without creating a line.
  abstract This moveTo(Float x, Float y)

  ** Add a line to the path from current point to given point.
  abstract This lineTo(Float x, Float y)

  ** Create circular arc centered at x, y with given radius.  The start
  ** angle and sweep angle are measured in degrees.  East is 0°, north 90°,
  ** west is 180°, and south is 270°.  Positive sweeps are counterclockwise
  ** and negative sweeps are clockwise.
  abstract This arc(Float x, Float y, Float radius, Float start, Float sweep)

  ** Add a Bézier curve to the path.  The cp1 and cp2 parameters specify
  ** the first and second control points; x and y specify the end point.
  abstract This curveTo(Float cp1x, Float cp1y, Float cp2x, Float cp2y, Float x, Float y)

  ** Add a quadratic Bézier curve to the path.  The cpx and cpy specify
  ** the control point; the x and y specify the end point.
  abstract This quadTo(Float cpx, Float cpy, Float x, Float y)

  ** Close the path by add a line from current point back to starting point.
  abstract This close()

}