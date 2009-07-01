//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 09  Andy Frank  Creation
//

/**
 * JfxGraphics implements gfx::Graphics using a JavaFx shim applet.
 */

function JfxGraphics(script)
{
  this.script = script;
  this.brush  = gfx_Color.black;
  this.pen    = gfx_Pen.defVal;
}

// Brush brush
JfxGraphics.prototype.brush = null
JfxGraphics.prototype.brush$get = function() { return this.brush }
JfxGraphics.prototype.brush$set = function(b)
{
  this.brush = b;
  if (b instanceof gfx_Color)
  {
    this.script.setColor(b.toCss());
  }
  // gradient
}

// Pen pen
JfxGraphics.prototype.pen = null
JfxGraphics.prototype.pen$get = function() { return this.pen }
JfxGraphics.prototype.pen$set = function(p)
{
  this.pen = p;
  this.script.setPen(p.width.valueOf());
  // lineCap
  // lineJoin
  // dashes
}

// Font font
JfxGraphics.prototype.font = null
JfxGraphics.prototype.font$get = function() { return this.font }
JfxGraphics.prototype.font$set = function(f)
{
  // TODO
}

// Bool antialias
JfxGraphics.prototype.antialias = null
JfxGraphics.prototype.antialias$get = function() { return this.antialias }
JfxGraphics.prototype.antialias$set = function(aa)
{
  // TODO
}

// Int alpha
JfxGraphics.prototype.alpha = null
JfxGraphics.prototype.alpha$get = function() { return this.alpha}
JfxGraphics.prototype.alpha$set = function(a)
{
  // TODO
}

// This drawLine(Int x1, Int y1, Int x2, Int y2)
JfxGraphics.prototype.drawLine = function(x1, y1, x2, y2)
{
  this.script.drawLine(x1.valueOf(), y1.valueOf(), x2.valueOf(), y2.valueOf());
  return this;
}

// This drawRect(Int x, Int y, Int w, Int h)
JfxGraphics.prototype.drawRect = function(x, y, w, h)
{
//  this.cx.strokeRect(x, y, w, h);
  return this;
}

// This fillRect(Int x, Int y, Int w, Int h)
JfxGraphics.prototype.fillRect = function(x, y, w, h)
{
//  this.cx.fillRect(x, y, w, h);
  return this;
}

// helper
JfxGraphics.prototype.oval = function(x, y, w, h)
{
  /*
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
  */
}

// This drawOval(Int x, Int y, Int w, Int h)
JfxGraphics.prototype.drawOval = function(x, y, w, h)
{
  /*
  this.oval(x, y, w, h)
  this.cx.stroke();
  */
  return this;
}

// This fillOval(Int x, Int y, Int w, Int h)
JfxGraphics.prototype.fillOval = function(x, y, w, h)
{
//  this.oval(x, y, w, h)
//  this.cx.fill();
  return this;
}

// This drawArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
JfxGraphics.prototype.drawArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
  return this;
}

// This fillArc(Int x, Int y, Int w, Int h, Int startAngle, Int arcAngle)
JfxGraphics.prototype.fillArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
  return this;
}

// This drawText(Str s, Int x, Int y)
JfxGraphics.prototype.drawText = function (s, x, y)
{
//  this.cx.fillText(s, x, y)
  return this;
}

// This drawImage(Image image, Int x, Int y)
JfxGraphics.prototype.drawImage = function (fanImg, x, y)
{
 // var jsImg = fwt_FwtEnvPeer.loadImage(fanImg);
 // this.cx.drawImage(jsImg, x, y)
  return this;
}

// This copyImage(Image image, Rect src, Rect dest)
JfxGraphics.prototype.copyImage = function (fanImg, src, dst)
{
//  var jsImg = fwt_FwtEnvPeer.loadImage(fanImg);
//  this.cx.drawImage(jsImg, src.x, src.y, src.w, src.h, dst.x, dst.y, dst.w, dst.h)
  return this;
}

// This translate(Int x, Int y)
JfxGraphics.prototype.translate = function (x, y)
{
  this.script.translate(x.valueOf(), y.valueOf());
  return this;
}

// This clip(Rect r)
JfxGraphics.prototype.clip = function (rect)
{
  /*
  this.cx.beginPath();
  this.cx.moveTo(rect.x, rect.y);
  this.cx.lineTo(rect.x+rect.w, rect.y);
  this.cx.lineTo(rect.x+rect.w, rect.y+rect.h);
  this.cx.lineTo(rect.x, rect.y+rect.h);
  this.cx.closePath();
  this.cx.clip();
  */
  return this
}

// Void push()
JfxGraphics.prototype.push = function ()
{
  /*
  this.cx.save();
  var state = new Object();
  state.brush     = this.brush;
  state.pen       = this.pen;
  state.font      = this.font;
  state.antialias = this.antialias;
  state.alpha     = this.alpha;
  this.stack.push(state);
  */
}

// Void pop()
JfxGraphics.prototype.pop = function ()
{
  /*
  this.cx.restore();
  var state = this.stack.pop();
  this.brush     = state.brush;
  this.pen       = state.pen;
  this.font      = state.font;
  this.antialias = state.antialias;
  this.alpha     = state.alpha;
  */
}

// Void dispose()
JfxGraphics.prototype.dispose = function ()
{
  // no-op
}

// state for fields in push/pop
JfxGraphics.prototype.stack = new Array();

