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
  self.onPaint(g)

  fwt_WidgetPeer.prototype.sync.call(this, self);
}

/**
 * fwt_Graphics implements Graphics to use HTML canvas.
 */
var fwt_Graphics = sys_Obj.$extend(sys_Obj);
//sys_Obj.$mixin(fwt_Graphics, gfx_Graphics);

fwt_Graphics.prototype.$ctor = function() {}

fwt_Graphics.prototype.cx = null
fwt_Graphics.prototype.brush = null

fwt_Graphics.prototype.brush$get = function() { return this.brush }
fwt_Graphics.prototype.brush$set = function(b)
{
  this.brush = b
  this.cx.fillStyle = b.toCss()
}

fwt_Graphics.prototype.fillRect = function(x, y, w, h)
{
  this.cx.fillRect(x, y, w, h);
}

