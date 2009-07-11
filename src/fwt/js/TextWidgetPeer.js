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
  if (self.multiLine) return fan.gfx.Size.make(p.w, 16*self.prefRows);
  return p;
}

fan.fwt.TextWidgetPeer.prototype.caretOffset$get = function(self) { return this.caretOffset; }
fan.fwt.TextWidgetPeer.prototype.caretOffset$set = function(self, val) { this.caretOffset = val; }
fan.fwt.TextWidgetPeer.prototype.caretOffset = 0;

fan.fwt.TextWidgetPeer.prototype.font$get = function(self) { return this.font; }
fan.fwt.TextWidgetPeer.prototype.font$set = function(self, val) { this.font = val; }
fan.fwt.TextWidgetPeer.prototype.font = null;

