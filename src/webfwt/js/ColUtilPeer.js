//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//

/**
 * ColUtil
 */
fan.webfwt.ColUtilPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.webfwt.ColUtilPeer.prototype.$ctor = function(self) {}

fan.webfwt.ColUtilPeer.writePng = function(table, out, col, row)
{
  var w = table.m_colw.get(col);
  var h = table.m_rowb.get(row).m_h;

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
  g.widget = table;
  g.paint(canvas, b, function() { table.paintCell(g, col, row, false, s) });

  // encode to PNG
  out.w("<img src='" + canvas.toDataURL("image/png") + "' />");

  // remove canvas
  document.body.removeChild(canvas);
}
