//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//

/**
 * FwtGraphics implements gfx::Graphics using HTML5 canvas.
 */

fan.fwt.FwtGraphics = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.FwtGraphics.prototype.$ctor = function() {}

fan.fwt.FwtGraphics.prototype.$typeof = function()
{
  return fan.fwt.FwtGraphics.$type;
}

fan.fwt.FwtGraphics.prototype.widget = null;
fan.fwt.FwtGraphics.prototype.size = null;
fan.fwt.FwtGraphics.prototype.cx = null;
fan.fwt.FwtGraphics.prototype.m_clip = null;

// canvas - <canvas> element
// bounds - fan.gfx.Rect
// f - JS function(fan.fwt.FwtGraphics)
fan.fwt.FwtGraphics.prototype.paint = function(canvas, bounds, f)
{
  this.size = bounds.size();
  this.m_clip = bounds;
  this.cx = canvas.getContext("2d");
  this.cx.save();
  this.cx.lineWidth = 1;
  this.cx.lineCap = "square";
  this.cx.textBaseline = "top";
  this.cx.font = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
  try
  {
    if (this.widget.peer.clearOnRepaint())
      this.cx.clearRect(bounds.m_x, bounds.m_y, bounds.m_w, bounds.m_h);
  }
  catch (err) {}
  this.brush$(fan.gfx.Color.m_black);
  this.pen$(fan.gfx.Pen.m_defVal);
  this.font$(fan.fwt.Desktop.sysFont());
  f(this);
  this.cx.restore();
}

// Brush brush
fan.fwt.FwtGraphics.prototype.m_brush = null
fan.fwt.FwtGraphics.prototype.brush   = function() { return this.m_brush }
fan.fwt.FwtGraphics.prototype.brush$  = function(b)
{
  this.m_brush = b;
  if (b instanceof fan.gfx.Color)
  {
    var style = b.toCss();
    this.cx.fillStyle = style;
    this.cx.strokeStyle = style;
  }
  else if (b instanceof fan.gfx.Gradient)
  {
    var x1 = b.m_x1;
    var y1 = b.m_y1;
    var x2 = b.m_x2;
    var y2 = b.m_y2;

    // handle percent
    if (b.m_x1Unit.symbol() == "%") x1 = this.size.m_w * (x1 / 100);
    if (b.m_y1Unit.symbol() == "%") y1 = this.size.m_h * (y1 / 100);
    if (b.m_x2Unit.symbol() == "%") x2 = this.size.m_w * (x2 / 100);
    if (b.m_y2Unit.symbol() == "%") y2 = this.size.m_h * (y2 / 100);

    // add stops
    var style = this.cx.createLinearGradient(x1, y1, x2, y2);
    var stops = b.m_stops;
    for (var i=0; i<stops.size(); i++)
    {
      var s = stops.get(i);
      style.addColorStop(s.m_pos, s.m_color.toCss());
    }

    this.cx.fillStyle = style;
    this.cx.strokeStyle = style;
  }
  else if (b instanceof fan.gfx.Pattern)
  {
    var jsImg = fan.fwt.FwtEnvPeer.loadImage(b.m_image);
    var style = (jsImg.width > 0 && jsImg.height > 0)
      ? this.cx.createPattern(jsImg, 'repeat')
      : "rgba(0,0,0,0)";
    this.cx.fillStyle = style;
    this.cx.strokeStyle = style;
  }
  else
  {
    fan.sys.Obj.echo("ERROR: unknown brush type: " + b);
  }
}

// Pen pen
fan.fwt.FwtGraphics.prototype.m_pen = null
fan.fwt.FwtGraphics.prototype.pen   = function() { return this.m_pen }
fan.fwt.FwtGraphics.prototype.pen$  = function(p)
{
  this.m_pen = p;
  this.cx.lineWidth = p.m_width;
  this.cx.lineCap   = p.capToStr();
  this.cx.lineJoin  = p.joinToStr();
  // dashes not supported
}

// Font font
fan.fwt.FwtGraphics.prototype.m_font = null
fan.fwt.FwtGraphics.prototype.font   = function() { return this.m_font }
fan.fwt.FwtGraphics.prototype.font$  = function(f)
{
  this.m_font = f;
  this.cx.font = fan.fwt.WidgetPeer.fontToCss(f);
}

// Bool antialias
fan.fwt.FwtGraphics.prototype.m_antialias = true;
fan.fwt.FwtGraphics.prototype.antialias   = function() { return this.m_antialias }
fan.fwt.FwtGraphics.prototype.antialias$  = function(aa)
{
  // Note: canvas has no control over anti-aliasing (Jun 09)
  this.m_antialias = aa;
}

// Int alpha
fan.fwt.FwtGraphics.prototype.m_alpha = 255;
fan.fwt.FwtGraphics.prototype.alpha   = function() { return this.m_alpha}
fan.fwt.FwtGraphics.prototype.alpha$  = function(a)
{
  this.m_alpha = a;
  this.cx.globalAlpha = a / 255;
}

// GraphicsPath path()
fan.fwt.FwtGraphics.prototype.path = function()
{
  this.cx.beginPath();
  var path = new fan.fwt.FwtGraphicsPath();
  path.cx = this.cx;
  return path;
}

// This drawLine(Int x1, Int y1, Int x2, Int y2)
fan.fwt.FwtGraphics.prototype.drawLine = function(x1, y1, x2, y2)
{
  this.cx.beginPath();
  this.cx.moveTo(x1+0.5, y1+0.5);
  this.cx.lineTo(x2+0.5, y2+0.5);
  this.cx.closePath();
  this.cx.stroke();
  return this;
}

// This drawPolyline(Point[] p)
fan.fwt.FwtGraphics.prototype.drawPolyline = function(p)
{
  this.cx.beginPath();
  for (var i=0; i<p.size(); i++)
  {
    var pt = p.get(i);
    if (i == 0) this.cx.moveTo(pt.m_x+0.5, pt.m_y+0.5);
    else this.cx.lineTo(pt.m_x+0.5, pt.m_y+0.5);
  }
  this.cx.stroke();
  return this;
}

// This drawPolygon(Point[] p)
fan.fwt.FwtGraphics.prototype.drawPolygon = function(p)
{
  this.cx.beginPath();
  for (var i=0; i<p.size(); i++)
  {
    var pt = p.get(i);
    if (i == 0) this.cx.moveTo(pt.m_x+0.5, pt.m_y+0.5);
    else this.cx.lineTo(pt.m_x+0.5, pt.m_y+0.5);
  }
  this.cx.closePath();
  this.cx.stroke();
  return this;
}

// This fillPolygon(Point[] p)
fan.fwt.FwtGraphics.prototype.fillPolygon = function(p)
{
  this.cx.beginPath();
  for (var i=0; i<p.size(); i++)
  {
    var pt = p.get(i);
    if (i == 0) this.cx.moveTo(pt.m_x, pt.m_y);
    else this.cx.lineTo(pt.m_x, pt.m_y);
  }
  this.cx.closePath();
  this.cx.fill();
  return this;
}

// This drawRect(Int x, Int y, Int w, Int h)
fan.fwt.FwtGraphics.prototype.drawRect = function(x, y, w, h)
{
  this.cx.strokeRect(x+0.5, y+0.5, w, h);
  return this;
}

// This fillRect(Int x, Int y, Int w, Int h)
fan.fwt.FwtGraphics.prototype.fillRect = function(x, y, w, h)
{
  this.cx.fillRect(x, y, w, h);
  return this;
}

// This drawRoundRect(Int x, Int y, Int w, Int h, Int wArc, Int hArc)
fan.fwt.FwtGraphics.prototype.drawRoundRect = function(x, y, w, h, wArc, hArc)
{
  this.pathRoundRect(x+0.5, y+0.5, w, h, wArc, hArc)
  this.cx.stroke();
  return this;
}

// This fillRoundRect(Int x, Int y, Int w, Int h, Int wArc, Int hArc)
fan.fwt.FwtGraphics.prototype.fillRoundRect = function(x, y, w, h, wArc, hArc)
{
  this.pathRoundRect(x, y, w, h, wArc, hArc)
  this.cx.fill();
  return this;
}

// generate path for a rounded rectangle
fan.fwt.FwtGraphics.prototype.pathRoundRect = function(x, y, w, h, wArc, hArc)
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

// helper
fan.fwt.FwtGraphics.prototype.oval = function(x, y, w, h)
{
  // Public Domain by Christopher Clay - http://canvaspaint.org/blog/
  var kappa = 4 * ((Math.sqrt(2) -1) / 3);
  var rx = w/2;
  var ry = h/2;
  var cx = x+rx+0.5;
  var cy = y+ry+0.5;

  this.cx.beginPath();
  this.cx.moveTo(cx, cy - ry);
  this.cx.bezierCurveTo(cx + (kappa * rx), cy - ry,  cx + rx, cy - (kappa * ry), cx + rx, cy);
  this.cx.bezierCurveTo(cx + rx, cy + (kappa * ry), cx + (kappa * rx), cy + ry, cx, cy + ry);
  this.cx.bezierCurveTo(cx - (kappa * rx), cy + ry, cx - rx, cy + (kappa * ry), cx - rx, cy);
  this.cx.bezierCurveTo(cx - rx, cy - (kappa * ry), cx - (kappa * rx), cy - ry, cx, cy - ry);
  this.cx.closePath();
}

// This drawOval(Int x, Int y, Int w, Int h)
fan.fwt.FwtGraphics.prototype.drawOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.stroke();
  return this;
}

// This fillOval(Int x, Int y, Int w, Int h)
fan.fwt.FwtGraphics.prototype.fillOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.fill();
  return this;
}

// This drawArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
fan.fwt.FwtGraphics.prototype.drawArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO FIXIT: support for elliptical arc curves
  var cx  = x + (w/2);
  var cy  = y + (h/2);
  var rad = Math.min(w/2, h/2);
  var sa  = Math.PI / 180 * startAngle;
  var ea  = Math.PI / 180 * (startAngle + arcAngle);

  this.cx.beginPath();
  this.cx.arc(cx, cy, rad, -sa, -ea, true);
  this.cx.stroke();
  return this;
}

// This fillArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
fan.fwt.FwtGraphics.prototype.fillArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO FIXIT: support for elliptical arc curves
  var cx = x + (w/2);
  var cy = y + (h/2);
  var radius = Math.min(w/2, h/2);

  var startRads = Math.PI / 180 * startAngle;
  var x1 = cx + (Math.cos(-startRads) * radius);
  var y1 = cy + (Math.sin(-startRads) * radius);

  var endRads = Math.PI / 180 * (startAngle + arcAngle);
  var x2 = cx + (Math.cos(-endRads) * radius);
  var y2 = cy + (Math.sin(-endRads) * radius);

  this.cx.beginPath();
  this.cx.moveTo(cx, cy);
  this.cx.lineTo(x1, y1);
  this.cx.arc(cx, cy, radius, -startRads, -endRads, true);
  this.cx.lineTo(x2, y2);
  this.cx.closePath();
  this.cx.fill();
  return this;
}

// This drawText(Str s, Int x, Int y)
fan.fwt.FwtGraphics.prototype.drawText = function (s, x, y)
{
  this.cx.fillText(s, x, y)
  return this;
}

// This drawImage(Image image, Int x, Int y)
fan.fwt.FwtGraphics.prototype.drawImage = function (fanImg, x, y)
{
  var jsImg = fan.fwt.FwtEnvPeer.loadImage(fanImg, this.widget);
  if (jsImg.width > 0 && jsImg.height > 0)
    this.cx.drawImage(jsImg, x, y)
  return this;
}

// This copyImage(Image image, Rect src, Rect dest)
fan.fwt.FwtGraphics.prototype.copyImage = function (fanImg, src, dst)
{
  var jsImg = fan.fwt.FwtEnvPeer.loadImage(fanImg);
  if (jsImg.width > 0 && jsImg.height > 0)
    this.cx.drawImage(jsImg, src.m_x, src.m_y, src.m_w, src.m_h, dst.m_x, dst.m_y, dst.m_w, dst.m_h)
  return this;
}

// This translate(Int x, Int y)
fan.fwt.FwtGraphics.prototype.translate = function (x, y)
{
  this.cx.translate(x, y)
  return this;
}

// This clip(Rect r)
fan.fwt.FwtGraphics.prototype.clip = function (rect)
{
  this.m_clip = this.m_clip.intersection(rect);
  this.cx.beginPath();
  this.cx.moveTo(rect.m_x, rect.m_y);
  this.cx.lineTo(rect.m_x+rect.m_w, rect.m_y);
  this.cx.lineTo(rect.m_x+rect.m_w, rect.m_y+rect.m_h);
  this.cx.lineTo(rect.m_x, rect.m_y+rect.m_h);
  this.cx.closePath();
  this.cx.clip();
  return this
}

// Rect clipBounds()
fan.fwt.FwtGraphics.prototype.clipBounds = function ()
{
  return this.m_clip;
}

// Void push()
fan.fwt.FwtGraphics.prototype.push = function ()
{
  this.cx.save();
  var state = new Object();
  state.brush     = this.m_brush;
  state.pen       = this.m_pen;
  state.font      = this.m_font;
  state.antialias = this.m_antialias;
  state.alpha     = this.m_alpha;
  state.clip      = this.m_clip;
  this.stack.push(state);
}

// Void pop()
fan.fwt.FwtGraphics.prototype.pop = function ()
{
  this.cx.restore();
  var state = this.stack.pop();
  this.m_brush     = state.brush;
  this.m_pen       = state.pen;
  this.m_font      = state.font;
  this.m_antialias = state.antialias;
  this.m_alpha     = state.alpha;
  this.m_clip      = state.clip;
}

// Void dispose()
fan.fwt.FwtGraphics.prototype.dispose = function ()
{
  // no-op
}

// state for fields in push/pop
fan.fwt.FwtGraphics.prototype.stack = new Array();

