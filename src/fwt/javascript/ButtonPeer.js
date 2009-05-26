//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * ButtonPeer.
 */
var fwt_ButtonPeer = sys_Obj.$extend(fwt_WidgetPeer);

fwt_ButtonPeer.prototype.$ctor = function(self)
{
  fwt_WidgetPeer.prototype.$ctor.call(this, self);
}

fwt_ButtonPeer.prototype.text$get = function() { return this.text; }
fwt_ButtonPeer.prototype.text$set = function(val)
{
  this.text = val;
  if (this.elem) this.elem.innerHTML = val;
}
fwt_ButtonPeer.prototype.text = "";

fwt_ButtonPeer.prototype.create = function(self)
{
  var button = document.createElement("input");
  button.type = "button";
  button.value = self.peer.text;

  var div = fwt_WidgetPeer.prototype.create.call(this, self);
  div.appendChild(button);
  return div;
}