//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * TextWidgetPeer.
 */
fan.fwt.TextWidgetPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TextWidgetPeer.prototype.$ctor = function(self) {}

fan.fwt.TextWidgetPeer.prototype.prefSize = function(self, hints)
{
  var p = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
  if (self.m_multiLine) return fan.gfx.Size.make(p.m_w, 16*self.m_prefRows);
  return p;
}

fan.fwt.TextWidgetPeer.prototype.caretOffset = function(self) { return this.m_caretOffset; }
fan.fwt.TextWidgetPeer.prototype.caretOffset$ = function(self, val) { this.m_caretOffset = val; }
fan.fwt.TextWidgetPeer.prototype.m_caretOffset = 0;

fan.fwt.TextWidgetPeer.prototype.font = function(self) { return this.m_font; }
fan.fwt.TextWidgetPeer.prototype.font$ = function(self, val) { this.m_font = val; }
fan.fwt.TextWidgetPeer.prototype.m_font = fan.fwt.Desktop.sysFont();

