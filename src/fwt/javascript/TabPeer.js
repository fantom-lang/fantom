//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jun 09  Andy Frank  Creation
//

/**
 * TabPeer.
 */
var fwt_TabPeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_TabPeer.prototype.$ctor = function(self) {}

fwt_TabPeer.prototype.text$get = function(self) { return this.text; }
fwt_TabPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_TabPeer.prototype.text = "";

fwt_TabPeer.prototype.image$get = function(self) { return this.image; }
fwt_TabPeer.prototype.image$set = function(self, val)
{
  this.image = val;
  fwt_FwtEnvPeer.loadImage(val)
}
fwt_TabPeer.prototype.image = null;

fwt_TabPeer.prototype.sync = function(self)
{
  while (this.elem.firstChild != null)
    this.elem.removeChild(this.elem.firstChild);

  var text = document.createTextNode(this.text);
  this.elem.appendChild(text);

  fwt_WidgetPeer.prototype.sync.call(this, self);
}