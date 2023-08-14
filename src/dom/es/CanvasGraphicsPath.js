//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

/**
 * CanvasGraphicsPath implements GraphicsPath using HTML5 canvas.
 */
class CanvasGraphicsPath extends sys.Obj {

  constructor() { super(); }
  typeof$() { return CanvasGraphicsPath.type$; }

  // canvas context
  cx;

  // This draw()
  draw()
  {
    this.cx.stroke();
    return this;
  }

  // This fill()
  fill()
  {
    this.cx.fill();
    return this;
  }

  // This clip()
  clip()
  {
    this.cx.clip();
    return this;
  }

  // This moveTo(Float x, Float y)
  moveTo(x, y)
  {
    this.cx.moveTo(x, y);
    return this;
  }

  // This lineTo(Float x, Float y)
  lineTo(x, y)
  {
    this.cx.lineTo(x, y);
    return this;
  }

  // This arc(Float x, Float y, Float radius, Float start, Float sweep)
  arc(x, y, radius, start, sweep)
  {
    const startRadians = (360 - start) * Math.PI / 180;
    const endRadians = startRadians - (sweep * Math.PI / 180);
    const counterclockwise = sweep > 0;
    this.cx.arc(x, y, radius, startRadians, endRadians, counterclockwise);
    return this;
  }

  // This curveTo(Float cp1x, Float cp1y, Float cp2x, Float cp2y, Float x, Float y)
  curveTo(cp1x, cp1y, cp2x, cp2y, x, y)
  {
    this.cx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
    return this;
  }

  // This quadTo(Float cpx, Float cpy, Float x, Float y)
  quadTo(cpx, cpy, x, y)
  {
    this.cx.quadraticCurveTo(cpx, cpy, x, y);
    return this;
  }

  // This close()
  close()
  {
    this.cx.closePath();
    return this;
  }
}