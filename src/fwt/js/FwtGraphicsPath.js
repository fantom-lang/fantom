//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 14  Brian Frank  Creation
//

/**
 * FwtGraphicsPath implements gfx::GraphicsPath using HTML5 canvas.
 */

fan.fwt.FwtGraphicsPath = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.FwtGraphicsPath.prototype.$ctor = function() {}

fan.fwt.FwtGraphicsPath.prototype.$typeof = function()
{
  return fan.fwt.FwtGraphicsPath.$type;
}

// canvas context
fan.fwt.FwtGraphicsPath.prototype.cx = null;

// This draw()
fan.fwt.FwtGraphicsPath.prototype.draw = function()
{
  this.cx.stroke();
  return this;
}

// This fill()
fan.fwt.FwtGraphicsPath.prototype.fill = function()
{
  this.cx.fill();
  return this;
}

// This clip()
fan.fwt.FwtGraphicsPath.prototype.clip = function()
{
  this.cx.clip();
  return this;
}

// This moveTo(Int x, Int y)
fan.fwt.FwtGraphicsPath.prototype.moveTo = function(x, y)
{
  this.cx.moveTo(x, y);
  return this;
}

// This lineTo(Int x, Int y)
fan.fwt.FwtGraphicsPath.prototype.lineTo = function(x, y)
{
  this.cx.lineTo(x, y);
  return this;
}

// This curveTo(Int cp1x, Int cp1y, Int cp2x, Int cp2y, Int x, Int y)
fan.fwt.FwtGraphicsPath.prototype.curveTo = function(cp1x, cp1y, cp2x, cp2y, x, y)
{
  this.cx.bezierCurveTo(cp1x+0.5, cp1y+0.5, cp2x+0.5, cp2y+0.5, x+0.5, y+0.5);
  return this;
}

// This close()
fan.fwt.FwtGraphicsPath.prototype.close = function()
{
  this.cx.closePath();
  return this;
}

