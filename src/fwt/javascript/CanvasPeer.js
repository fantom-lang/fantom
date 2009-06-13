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