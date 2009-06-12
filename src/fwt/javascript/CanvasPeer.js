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
  var div = this.elem;
  while (div.firstChild != null) div.removeChild(div.firstChild);

  var c = document.createElement("canvas");
  div.appendChild(c);

  var cx = c.getContext("2d")
  cx.fillStyle = "rgb(100,100,100)";
  cx.fillRect (0, 0, 500, 500);

  /* this does not work
  var g = fwt_Graphics()
  g.cx = c.getContext("2d");
  self.onPaint(g)
  */

  fwt_WidgetPeer.prototype.sync.call(this, self);
}

/**
 * fwt_Graphics implements Graphics to use HTML canvas.
 */
var fwt_Graphics = sys_Obj.$extend(sys_Obj);
sys_Obj.$mixin(fwt_Graphics, gfx_Graphics);

fwt_Graphics.prototype.cx = null

fwt_Graphics.prototype.fillRect = function(x, y, w, h)
{
  cx.fillStyle = "rgb(200,0,0)";
  cx.fillRect (x, y, w, h);
}

