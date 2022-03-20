//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using [java] java.awt::Graphics2D
using [java] java.awt.geom::Path2D$Double as Path2D
using [java] java.awt.geom::Arc2D$Double as Arc2D
using graphics

**
** Java2D graphics path
**
class Java2DGraphicsPath : GraphicsPath
{
  new make(Graphics2D g)
  {
    this.g = g
    this.path = Path2D()
  }

  override This draw()
  {
    g.draw(path)
    return this
  }

  override This fill()
  {
    g.fill(path)
    return this
  }

  override This clip()
  {
    g.clip(path)
    return this
  }

  override This moveTo(Float x, Float y)
  {
    path.moveTo(x, y)
    return this
  }

  override This lineTo(Float x, Float y)
  {
    path.lineTo(x, y)
    return this
  }

  override This arc(Float x, Float y, Float radius, Float start, Float sweep)
  {
    path.append(Arc2D(x-radius, y-radius, radius*2f, radius*2f, start, sweep,  Arc2D.OPEN), true)
    return this
  }

  override This curveTo(Float cp1x, Float cp1y, Float cp2x, Float cp2y, Float x, Float y)
  {
    path.curveTo(cp1x, cp1y, cp2x, cp2y, x, y)
    return this
  }

  override This quadTo(Float cpx, Float cpy, Float x, Float y)
  {
    path.quadTo(cpx, cpy, x, y)
    return this
  }

  override This close()
  {
    path.closePath
    return this
  }

  private Graphics2D g
  private Path2D path
}


