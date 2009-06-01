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
fwt_ButtonPeer.prototype.$ctor = function(self) {}

fwt_ButtonPeer.prototype.font$get = function(self) { return this.font; }
fwt_ButtonPeer.prototype.font$set = function(self, val) { this.font = val; }
fwt_ButtonPeer.prototype.font = null;

fwt_ButtonPeer.prototype.image$get = function(self) { return this.image; }
fwt_ButtonPeer.prototype.image$set = function(self, val) { this.image = val; }
fwt_ButtonPeer.prototype.image = null;

fwt_ButtonPeer.prototype.selected$get = function(self) { return this.selected; }
fwt_ButtonPeer.prototype.selected$set = function(self, val) { this.selected = val; }
fwt_ButtonPeer.prototype.selected = false;

fwt_ButtonPeer.prototype.text$get = function(self) { return this.text; }
fwt_ButtonPeer.prototype.text$set = function(self, val) { this.text = val; }
fwt_ButtonPeer.prototype.text = "";

fwt_ButtonPeer.prototype.create = function(parentElem)
{
  var button = document.createElement("input");
  button.type = "button";
  var div = this.emptyDiv();
  div.appendChild(button);
  parentElem.appendChild(div);
  return div;
}

fwt_ButtonPeer.prototype.sync = function(self)
{
  var b = this.elem.firstChild;
  b.value = this.text;
  b.onclick = function(event)
  {
    var list = self.onAction.list();
    for (var i=0; i<list.length; i++) list[i](event);
  }
  fwt_WidgetPeer.prototype.sync.call(this, self);
}