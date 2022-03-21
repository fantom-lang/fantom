//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

/**
 * CanvasGraphicsPath implements GraphicsPath using HTML5 canvas.
 */

fan.dom.CanvasGraphicsPath = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.CanvasGraphicsPath.prototype.$ctor = function() {}

fan.dom.CanvasGraphicsPath.prototype.$typeof = function()
{
  return fan.dom.CanvasGraphicsPath.$type;
}

// canvas context
fan.dom.CanvasGraphicsPath.prototype.cx = null;

// This draw()
fan.dom.CanvasGraphicsPath.prototype.draw = function()
{
  this.cx.stroke();
  return this;
}

// This fill()
fan.dom.CanvasGraphicsPath.prototype.fill = function()
{
  this.cx.fill();
  return this;
}

// This clip()
fan.dom.CanvasGraphicsPath.prototype.clip = function()
{
  this.cx.clip();
  return this;
}

// This moveTo(Float x, Float y)
fan.dom.CanvasGraphicsPath.prototype.moveTo = function(x, y)
{
  this.cx.moveTo(x, y);
  return this;
}

// This lineTo(Float x, Float y)
fan.dom.CanvasGraphicsPath.prototype.lineTo = function(x, y)
{
  this.cx.lineTo(x, y);
  return this;
}

// This arc(Float x, Float y, Float radius, Float start, Float sweep)
fan.dom.CanvasGraphicsPath.prototype.arc = function(x, y, radius, start, sweep)
{
  var startRadians = (360 - start) * Math.PI / 180;
  var endRadians = startRadians - (sweep * Math.PI / 180);
  var counterclockwise = sweep > 0;
  this.cx.arc(x, y, radius, startRadians, endRadians, counterclockwise);
  return this;
}

// This curveTo(Float cp1x, Float cp1y, Float cp2x, Float cp2y, Float x, Float y)
fan.dom.CanvasGraphicsPath.prototype.curveTo = function(cp1x, cp1y, cp2x, cp2y, x, y)
{
  this.cx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  return this;
}

// This quadTo(Float cpx, Float cpy, Float x, Float y)
fan.dom.CanvasGraphicsPath.prototype.quadTo = function(cpx, cpy, x, y)
{
  this.cx.quadraticCurveTo(cpx, cpy, x, y);
  return this;
}

// This close()
fan.dom.CanvasGraphicsPath.prototype.close = function()
{
  this.cx.closePath();
  return this;
}