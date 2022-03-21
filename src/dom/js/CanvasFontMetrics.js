//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//

/**
 * CanvasFontMetrics implements FontMetrics using HTML5 canvas TextMetrics.
 */

fan.dom.CanvasFontMetrics = fan.sys.Obj.$extend(fan.graphics.FontMetrics);
fan.dom.CanvasFontMetrics.prototype.$ctor = function() {}

fan.dom.CanvasFontMetrics.prototype.$typeof = function()
{
  return fan.dom.CanvasFontMetrics.$type;
}

fan.dom.CanvasFontMetrics.prototype.init = function(cx)
{
  var m = cx.measureText("Hg");
  this.cx = cx
  this.m_ascent =  Math.ceil(m.actualBoundingBoxAscent);
  this.m_descent = Math.ceil(m.actualBoundingBoxDescent);
  this.m_leading = Math.ceil(m.fontBoundingBoxAscent) - this.m_ascent;
  this.m_height = this.m_leading + this.m_ascent + this.m_descent;
  return this;
}

fan.dom.CanvasFontMetrics.prototype.height = function() { return this.m_height; }

fan.dom.CanvasFontMetrics.prototype.leading = function() { return this.m_leading; }

fan.dom.CanvasFontMetrics.prototype.ascent = function() { return this.m_ascent; }

fan.dom.CanvasFontMetrics.prototype.descent = function() { return this.m_descent; }

fan.dom.CanvasFontMetrics.prototype.width = function(str) { return this.cx.measureText(str).width; }

