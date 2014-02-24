//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jun 14  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.UnsupportedErr;
import fan.gfx.*;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Path;

public class FwtGraphicsPath implements GraphicsPath
{
  public FwtGraphicsPath(FwtGraphics g)
  {
    this.g = g;
    this.path = new Path(g.gc.getDevice());
  }

  public GraphicsPath draw()
  {
    g.gc.drawPath(path);
    path.dispose();
    return this;
  }

  public GraphicsPath fill()
  {
    g.gc.fillPath(path);
    path.dispose();
    return this;
  }

  public GraphicsPath clip()
  {
    path.dispose();
    throw UnsupportedErr.make("SWT GraphicPath.clip");
  }

  public GraphicsPath moveTo(long x, long y)
  {
    path.moveTo((int)x, (int)y);
    return this;
  }

  public GraphicsPath lineTo(long x, long y)
  {
    path.lineTo((int)x, (int)y);
    return this;
  }

  public GraphicsPath curveTo(long cp1x, long cp1y, long cp2x, long cp2y, long x, long y)
  {
    path.cubicTo((int)cp1x, (int)cp1y, (int)cp2x, (int)cp2y, (int)x, (int)y);
    return this;
  }

  public GraphicsPath close()
  {
    path.close();
    return this;
  }

  final FwtGraphics g;
  final Path path;

}