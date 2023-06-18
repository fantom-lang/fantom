//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//

/**
 * CanvasGraphics implements Graphics using HTML5 canvas.
 */

fan.dom.CanvasGraphics = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.CanvasGraphics.prototype.$ctor = function() {}

fan.dom.CanvasGraphics.prototype.$typeof = function()
{
  return fan.dom.CanvasGraphics.$type;
}

// render
fan.dom.CanvasGraphics.render = function(canvas, cb)
{
  var cx = canvas.peer.elem.getContext("2d");
  var g = new fan.dom.CanvasGraphics();
  if (!canvas.peer.m_inited)
  {
    // first time thru scale by half a pixel to avoid blurry lines
    canvas.peer.m_inited = true;
    cx.translate(0.5, 0.5);
  }
  g.cx = cx;
  cb.call(g);
}

// Paint paint
fan.dom.CanvasGraphics.prototype.m_paint = fan.graphics.Color.m_black;
fan.dom.CanvasGraphics.prototype.paint  = function() { return this.m_paint }
fan.dom.CanvasGraphics.prototype.paint$ = function(x)
{
  this.m_paint = x;
  this.cx.fillStyle = x.asColorPaint().toStr();
  this.cx.strokeStyle = x.asColorPaint().toStr();
}

// Color color
fan.dom.CanvasGraphics.prototype.color  = function() { return this.m_paint.asColorPaint(); }
fan.dom.CanvasGraphics.prototype.color$ = function(x) { this.paint$(x); }

// Stroke stroke
fan.dom.CanvasGraphics.prototype.m_stroke = fan.graphics.Stroke.m_defVal;
fan.dom.CanvasGraphics.prototype.stroke  = function() { return this.m_stroke }
fan.dom.CanvasGraphics.prototype.stroke$  = function(x)
{
  this.m_stroke       = x;
  this.cx.lineWidth   = x.m_width;
  this.cx.lineCap     = x.m_cap.toStr();
  this.cx.lineJoin    = x.m_join == fan.graphics.StrokeJoin.m_radius ? "round" : x.m_join.toStr();
  this.cx.setLineDash(this.toStrokeDash(x.m_dash));
}

fan.dom.CanvasGraphics.prototype.toStrokeDash = function(x)
{
  if (x == null) return [];
  return fan.graphics.GeomUtil.parseFloatList(x).m_values;
}

// Float alpha
fan.dom.CanvasGraphics.prototype.m_alpha = null
fan.dom.CanvasGraphics.prototype.alpha   = function() { return this.m_alpha }
fan.dom.CanvasGraphics.prototype.alpha$  = function(x)
{
  this.m_alpha = x;
  this.cx.globalAlpha = x;
}

// Font font
fan.dom.CanvasGraphics.prototype.m_font = null
fan.dom.CanvasGraphics.prototype.font   = function() { return this.m_font }
fan.dom.CanvasGraphics.prototype.font$  = function(x)
{
  if (this.m_font === x) return;
  this.m_font = x;
  this.cx.font = x.toStr();
}

// FontMetrics metrics()
fan.dom.CanvasGraphics.prototype.metrics = function()
{
  return new fan.dom.CanvasFontMetrics().init(this.cx);
}

// GraphicsPath path()
fan.dom.CanvasGraphics.prototype.path = function()
{
  this.cx.beginPath();
  var path = new fan.dom.CanvasGraphicsPath();
  path.cx = this.cx;
  return path;
}

// This drawLine(Float x1, Float y1, Float x2, Float y2)
fan.dom.CanvasGraphics.prototype.drawLine = function(x1, y1, x2, y2)
{
  this.cx.beginPath();
  this.cx.moveTo(x1, y1);
  this.cx.lineTo(x2, y2);
  this.cx.stroke();
  return this;
}

// This drawRect(Float x, Float y, Float w, Float h)
fan.dom.CanvasGraphics.prototype.drawRect = function(x, y, w, h)
{
  this.cx.strokeRect(x, y, w, h);
  return this;
}

// This fillRect(Float x, Float y, Float w, Float h)
fan.dom.CanvasGraphics.prototype.fillRect = function(x, y, w, h)
{
  this.cx.fillRect(x, y, w, h);
  return this;
}

// This clipRect(Float x, Float y, Float w, Float h)
fan.dom.CanvasGraphics.prototype.clipRect = function(x, y, w, h)
{
  this.cx.beginPath();
  this.cx.rect(x, y, w, h)
  this.cx.clip();
  return this;
}

// This drawRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
fan.dom.CanvasGraphics.prototype.drawRoundRect = function(x, y, w, h, wArc, hArc)
{
  this.pathRoundRect(x, y, w, h, wArc, hArc);
  this.cx.stroke();
  return this;
}

// This fillRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
fan.dom.CanvasGraphics.prototype.fillRoundRect = function(x, y, w, h, wArc, hArc)
{
  this.pathRoundRect(x, y, w, h, wArc, hArc);
  this.cx.fill();
  return this;
}

// generate path for a rounded rectangle
fan.dom.CanvasGraphics.prototype.pathRoundRect = function(x, y, w, h, wArc, hArc)
{
  this.cx.beginPath();
  this.cx.moveTo(x + wArc, y);
  this.cx.lineTo(x + w - wArc, y);
  this.cx.quadraticCurveTo(x + w, y, x + w, y + hArc);
  this.cx.lineTo(x + w, y + h - hArc);
  this.cx.quadraticCurveTo(x + w, y + h , x + w - wArc, y + h);
  this.cx.lineTo(x + wArc, y + h);
  this.cx.quadraticCurveTo(x, y + h , x, y + h - hArc);
  this.cx.lineTo(x, y + hArc);
  this.cx.quadraticCurveTo(x, y, x + wArc, y);
}

// This drawText(Str s, Float x, Float y)
fan.dom.CanvasGraphics.prototype.drawText = function (s, x, y)
{
  this.cx.fillText(s, x, y);
  return this;
}

// This drawImage(Image img, Float x, Float y, Float w := img.w, Float h := img.h)
fan.dom.CanvasGraphics.prototype.drawImage = function (img, x, y, w, h)
{
  if (w === undefined) w = img.w();
  if (h === undefined) h = img.h();
  this.cx.drawImage(img.peer.elem, x, y, w, h);
  return this;
}

// This drawImageRegion(Image img, Rect src, Rect dst)
fan.dom.CanvasGraphics.prototype.drawImageRegion = function (img, src, dst)
{
  this.cx.drawImage(img.peer.elem,
    src.m_x, src.m_y, src.m_w, src.m_h,
    dst.m_x, dst.m_y, dst.m_w, dst.m_h);
  return this;
}

// This translate(Float x, Float y)
fan.dom.CanvasGraphics.prototype.translate = function (x, y)
{
  this.cx.translate(x, y);
  return this;
}

// This transform(Transform transform)
fan.dom.CanvasGraphics.prototype.transform = function (t)
{
  this.cx.transform(t.m_a, t.m_b, t.m_c, t.m_d, t.m_e, t.m_f);
  return this;
}

// This push()
fan.dom.CanvasGraphics.prototype.push = function (r)
{
  this.cx.save();
  if (r !== undefined)
  {
    this.cx.beginPath();
    this.cx.translate(r.m_x, r.m_y);
    this.cx.rect(0, 0, r.m_w, r.m_h);
    this.cx.clip();
  }
  var state = new Object();
  state.paint     = this.m_paint;
  state.color     = this.m_color;
  state.stroke    = this.m_stroke;
  state.alpha     = this.m_alpha;
  state.font      = this.m_font;
  this.stack.push(state);
  return this;
}

// This pop()
fan.dom.CanvasGraphics.prototype.pop = function ()
{
  this.cx.restore();
  var state = this.stack.pop();
  this.m_paint  = state.paint;
  this.m_color  = state.color;
  this.m_stroke = state.stroke;
  this.m_alpha  = state.alpha;
  this.m_font   = state.font;
  return this;
}

// state for fields in push/pop
fan.dom.CanvasGraphics.prototype.stack = new Array();

