//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 2011  Andy Frank  Creation
//

/**
 * CanvasTablePeer.
 */
fan.webfwt.CanvasTablePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.CanvasTablePeer.prototype.$ctor = function(self) {}

fan.webfwt.CanvasTablePeer.prototype.writePng = function(self, out, col, row)
{
  var w = self.m_colw.get(col);
  var h = self.m_rowb.get(row).m_h;

  // add temp canvas
  var canvas = document.createElement("canvas");
  canvas.width  = w;
  canvas.height = h;
  canvas.style.display = "none";
  document.body.appendChild(canvas);

  // render cell
  var g = new fan.fwt.FwtGraphics();
  var s = fan.gfx.Size.make(w, h);
  var b = fan.gfx.Rect.make(0, 0, w, h);
  g.widget = self;
  g.paint(canvas, b, function() { self.paintCell(g, col, row, false, s) });

  // encode to PNG
  out.w("<img src='" + canvas.toDataURL("image/png") + "' />");

  // remove canvas
  document.body.removeChild(canvas);
}

