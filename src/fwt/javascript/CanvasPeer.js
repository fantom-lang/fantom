//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//

/**
 * CanvasPeer.
 */
var fwt_CanvasPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_CanvasPeer.prototype.$ctor = function(self) {}

fwt_CanvasPeer.prototype.sync = function(self)
{
  // remove existing elements
  var div = this.elem;
  while (div.firstChild != null) div.removeChild(div.firstChild);

  // create new canvas element in my div
  var c = document.createElement("canvas");
  var size = this.size
  c.width  = size.w;
  c.height = size.h;
  div.appendChild(c);

  // repaint canvas using Canvas.onPaint callback
  var g = new fwt_Graphics()
  g.cx = c.getContext("2d");
  g.cx.lineWidth = 1
  g.cx.lineCap = "square"
  g.cx.textBaseline = "top"
  self.onPaint(g)

  fwt_WidgetPeer.prototype.sync.call(this, self);
}

/**
 * fwt_Graphics implements Graphics to use HTML canvas.
 */
var fwt_Graphics = sys_Obj.$extend(sys_Obj);

fwt_Graphics.prototype.$ctor = function() {}

fwt_Graphics.prototype.cx = null

fwt_Graphics.prototype.brush = null
fwt_Graphics.prototype.brush$get = function() { return this.brush }
fwt_Graphics.prototype.brush$set = function(b)
{
  var style = b.toCss()
  this.brush = b
  this.cx.fillStyle = style
  this.cx.strokeStyle = style
}

fwt_Graphics.prototype.pen = null
fwt_Graphics.prototype.pen$get = function() { return this.pen }
fwt_Graphics.prototype.pen$set = function(p)
{
  this.pen = p
  this.cx.lineWidth = p.width
  /* these don't appear to work in any browser and actually
     fail in FireFox, so just keep them commented out for now
  this.cx.lineCap = p.capToStr
  this.cx.lineJoin = p.joinToStr
  */
  // dashes not supported
}

fwt_Graphics.prototype.font = null
fwt_Graphics.prototype.font$get = function() { return this.font }
fwt_Graphics.prototype.font$set = function(f)
{
  this.font = t
  // TODO
}

fwt_Graphics.prototype.antialias = null
fwt_Graphics.prototype.antialias$get = function() { return this.antialias }
fwt_Graphics.prototype.antialias$set = function(aa)
{
  this.antialias = aa
  // TODO
}

fwt_Graphics.prototype.alpha = null
fwt_Graphics.prototype.alpha$get = function() { return this.alpha}
fwt_Graphics.prototype.alpha$set = function(a)
{
  this.alpha = a
  // TODO
}

fwt_Graphics.prototype.drawLine = function(x1, y1, x2, y2)
{
  this.cx.beginPath();
  this.cx.moveTo(x1, y1);
  this.cx.lineTo(x2, y2);
  this.cx.closePath();
  this.cx.stroke();
}

fwt_Graphics.prototype.drawRect = function(x, y, w, h)
{
  this.cx.strokeRect(x, y, w, h);
}

fwt_Graphics.prototype.fillRect = function(x, y, w, h)
{
  this.cx.fillRect(x, y, w, h);
}

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

fwt_Graphics.prototype.drawOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.stroke();
}

fwt_Graphics.prototype.fillOval = function(x, y, w, h)
{
  this.oval(x, y, w, h)
  this.cx.fill();
}

fwt_Graphics.prototype.drawArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
}

fwt_Graphics.prototype.fillArc = function(x, y, w, h, startAngle, arcAngle)
{
  // TODO
}

fwt_Graphics.prototype.drawText = function (s, x, y)
{
  this.cx.fillText(s, x, y)
}

fwt_Graphics.prototype.drawImage = function (img, x, y)
{
  // TODO
}

fwt_Graphics.prototype.copyImage = function (img, src, dest)
{
  // TODO
}

fwt_Graphics.prototype.translate = function (x, y)
{
  this.cx.translate(x, y)
}

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

fwt_Graphics.prototype.push = function ()
{
  // TODO
}

fwt_Graphics.prototype.pop = function ()
{
  // TODO
}

fwt_Graphics.prototype.dispose = function ()
{
  // no-op
}


