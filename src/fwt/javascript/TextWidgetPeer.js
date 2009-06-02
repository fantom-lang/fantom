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
var fwt_TextWidgetPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_TextWidgetPeer.prototype.$ctor = function(self) {}

fwt_TextWidgetPeer.prototype.prefSize = function(self, hints)
{
  // TODO - temp till we fix the fan code
  var pref = fwt_WidgetPeer.prototype.prefSize.call(this, self, hints);
  return gfx_Size.make(0, pref.h);
}

fwt_TextWidgetPeer.prototype.caretOffset$get = function(self) { return this.caretOffset; }
fwt_TextWidgetPeer.prototype.caretOffset$set = function(self, val) { this.caretOffset = val; }
fwt_TextWidgetPeer.prototype.caretOffset = 0;

fwt_TextWidgetPeer.prototype.font$get = function(self) { return this.font; }
fwt_TextWidgetPeer.prototype.font$set = function(self, val) { this.font = val; }
fwt_TextWidgetPeer.prototype.font = null;

