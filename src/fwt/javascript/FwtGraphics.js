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

var fwt_Graphics = sys_Obj.$extend(sys_Obj);

fwt_Graphics.prototype.$ctor = function() {}

fwt_Graphics.prototype.cx = null

// Brush brush
fwt_Graphics.prototype.brush = null
fwt_Graphics.prototype.brush$get = function() { return this.brush }
fwt_Graphics.prototype.brush$set = function(b)
{
  this.brush = b;
  if (b instanceof gfx_Color)
  {
    var style = b.toCss();
    this.cx.fillStyle = style;
    this.cx.strokeStyle = style;
  }
  else
  {
    var style = this.cx.createLinearGradient(b.p1.x, b.p1.y, b.p2.x, b.p2.y);
    style.addColorStop(0, b.c1.toCss());
    style.addColorStop(1, b.c2.toCss());
    this.cx.fillStyle = style;
    this.cx.strokeStyle = style;
  }
}

// Pen pen
fwt_Graphics.prototype.pen = null
fwt_Graphics.prototype.pen$get = function() { return this.pen }
fwt_Graphics.prototype.pen$set = function(p)
{
  this.pen = p;
  this.cx.lineWidth = p.width;
  this.cx.lineCap   = p.capToStr();
  this.cx.lineJoin  = p.joinToStr();
  // dashes not supported
}

// Font font
fwt_Graphics.prototype.font = null
fwt_Graphics.prototype.font$get = function() { return this.font }
fwt_Graphics.prototype.font$set = function(f)
{
  this.font = f;
  this.cx.font = f.toStr();
}

// Bool antialias
fwt_Graphics.prototype.antialias = null
fwt_Graphics.prototype.antialias$get = function() { return this.antialias }
fwt_Graphics.prototype.antialias$set = function(aa)
{
  // Note: canvas has no control over anti-aliasing (Jun 09)
  this.antialias = aa;
}

// Int alpha
fwt_Graphics.prototype.alpha = null
fwt_Graphics.prototype.alpha$get = function() { return this.alpha}
fwt_Graphics.prototype.alpha$set = function(a)
{
  this.alpha = a;
  this.cx.globalAlpha = a / 255;
}

// This drawLine(Int x1, Int y1, Int x2, Int y2)
fwt_Graphics.prototype.drawLine = function(x1, y1, x2, y2)
{
  this.cx.beginPath();
  this.cx.moveTo(x1+0.5, y1+0.5);
  this.cx.lineTo(x2+0.5, y2+0.5);
  this.cx.closePath();
  this.cx.stroke();
  return this;
}

// This drawRect(Int x, Int y, Int w, Int h)
fwt_Graphics.prototype.drawRect = function(x, y, w, h)
{
  this.cx.strokeRect(x+0.5, y+0.5, w, h);
  return this;
}

// This fillRect(Int x, Int y, Int w, Int h)
fwt_Graphics.prototype.fillRect = function(x, y, w, h)
{
  this.cx.fillRect(x, y, w, h);
  return this;
}

// helper
fwt_Graphics.prototype.oval = function(x, y, w, h)
{
  // Public Domain by Christopher Clay - http://canvaspaint.org/blog/
  var kappa = 4 * ((Math.sqrt(2) -1) / 3);
  var rx = w/2;
  var ry = h/2;
  var cx = x+rx;
  var cy = y+ry;

  this.cx.beginPath();
  this.cx.moveTo(cx, cy - ry);
  this.cx.bezierCurveTo(cx + (kappa * rx), cy - ry,  cx + rx, cy - (kappa * ry), cx + rx, cy);
  this.cx.bezierCurveTo(cx + rx, cy + (kappa * ry), cx + (kappa * rx), cy + ry, cx, cy + ry);
  this.cx.bezierCurveTo(cx - (kappa * rx), cy + ry, cx - rx, cy + (kappa * ry), cx - rx, cy);
  this.cx.bezierCurveTo(cx - rx, cy - (kappa * ry), cx - (kappa * rx), cy - ry, cx, cy - ry);
  this.cx.closePath();
}

// This drawOval(Int x, Int y, Int w, Int h)
fwt_Graphics.prototype.drawOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.stroke();
  return this;
}

// This fillOval(Int x, Int y, Int w, Int h)
fwt_Graphics.prototype.fillOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.fill();
  return this;
}

// This drawArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
fwt_Graphics.prototype.drawArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
  return this;
}

// This fillArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
fwt_Graphics.prototype.fillArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
  return this;
}

// This drawText(Str s, Int x, Int y)
fwt_Graphics.prototype.drawText = function (s, x, y)
{
  this.cx.fillText(s, x, y)
  return this;
}

// This drawImage(Image image, Int x, Int y)
fwt_Graphics.prototype.drawImage = function (fanImg, x, y)
{
  var jsImg = fwt_FwtEnvPeer.loadImage(fanImg);
  this.cx.drawImage(jsImg, x, y)
  return this;
}

// This copyImage(Image image, Rect src, Rect dest)
fwt_Graphics.prototype.copyImage = function (fanImg, src, dst)
{
  var jsImg = fwt_FwtEnvPeer.loadImage(fanImg);
  this.cx.drawImage(jsImg, src.x, src.y, src.w, src.h, dst.x, dst.y, dst.w, dst.h)
  return this;
}

// This translate(Int x, Int y)
fwt_Graphics.prototype.translate = function (x, y)
{
  this.cx.translate(x, y)
  return this;
}

// This clip(Rect r)
fwt_Graphics.prototype.clip = function (rect)
{
  this.cx.beginPath();
  this.cx.moveTo(rect.x, rect.y);
  this.cx.lineTo(rect.x+rect.w, rect.y);
  this.cx.lineTo(rect.x+rect.w, rect.y+rect.h);
  this.cx.lineTo(rect.x, rect.y+rect.h);
  this.cx.closePath();
  this.cx.clip();
  return this
}

// Void push()
fwt_Graphics.prototype.push = function ()
{
  this.cx.save();
  var state = new Object();
  state.brush     = this.brush;
  state.pen       = this.pen;
  state.font      = this.font;
  state.antialias = this.antialias;
  state.alpha     = this.alpha;
  this.stack.push(state);
}

// Void pop()
fwt_Graphics.prototype.pop = function ()
{
  this.cx.restore();
  var state = this.stack.pop();
  this.brush     = state.brush;
  this.pen       = state.pen;
  this.font      = state.font;
  this.antialias = state.antialias;
  this.alpha     = state.alpha;
}

// Void dispose()
fwt_Graphics.prototype.dispose = function ()
{
  // no-op
}

// state for fields in push/pop
fwt_Graphics.prototype.stack = new Array();

