//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jul 08  Brian Frank  Creation
//

**
** Brush defines how a shape is filled
**   - `Color` is a solid brush
**   - `Gradient` used to paint a color gradient
**
mixin Brush
{
}

**************************************************************************
** Gradient
**************************************************************************

**
** Fills a shape using a two color linear gradient.
**
const class Gradient : Brush
{

  // keep this stuff hidden for now until I figure out real design;
  // I'd like to do real SVG percent based stops, in which case we'd
  // probably expose something like GradientStop[]; but SWT doesn't
  // provide too much support

  internal const Point p1
  internal const Point p2
  internal const Color c1
  internal const Color c2
  private new make() {}

  **
  ** Construct a two color linear gradient between the two points.
  **
  static Gradient makeLinear(Point p1, Color c1, Point p2, Color c2)
  {
    return make { p1 = p1; c1 = c1; p2 = p2; c2 = c2 }
  }

  **
  ** Hash the fields.
  **
  override Int hash()
  {
    return (p1.hash << 45) ^ (p2.hash << 30) ^ (c1.hash << 45) ^ c2.hash
  }

  **
  ** Equality is based on fields.
  **
  override Bool equals(Obj? obj)
  {
    that := obj as Gradient
    if (that == null) return false
    return this.p1 == that.p1 && this.p2 == that.p2 &&
           this.c1 == that.c1 && this.c2 == that.c2
  }

  **
  ** Return '"[point1:color1; point2:color2]"'.
  ** This string format is subject to change.
  **
  override Str toStr()
  {
    return "[$p1:$c1; $p2:$c2]"
  }
}


