//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 May 09  Andy Frank  Creation
//

/**
 * MenuItemPeer.
 */
fan.fwt.MenuItemPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.MenuItemPeer.prototype.$ctor = function(self) {}

fan.fwt.MenuItemPeer.prototype.selected$get = function(self) { return this.selected; }
fan.fwt.MenuItemPeer.prototype.selected$set = function(self, val) { this.selected = val; }
fan.fwt.MenuItemPeer.prototype.selected = false;

fan.fwt.MenuItemPeer.prototype.text$get = function(self) { return this.text; }
fan.fwt.MenuItemPeer.prototype.text$set = function(self, val) { this.text = val; }
fan.fwt.MenuItemPeer.prototype.text = "";

fan.fwt.MenuItemPeer.prototype.accelerator$get = function(self) { return this.accelerator; }
fan.fwt.MenuItemPeer.prototype.accelerator$set = function(self, val) { this.accelerator = val; }
fan.fwt.MenuItemPeer.prototype.accelerator = null;

fan.fwt.MenuItemPeer.prototype.image$get = function(self) { return this.image; }
fan.fwt.MenuItemPeer.prototype.image$set = function(self, val) { this.image = val; }
fan.fwt.MenuItemPeer.prototype.image = null;

fan.fwt.MenuItemPeer.prototype.sync = function(self)
{
  var div = this.elem;
  while (div.firstChild != null) div.removeChild(div.firstChild);
  div.appendChild(document.createTextNode(this.text));

  with (div.style)
  {
    div.style.cursor = "default";
    div.style.padding = "1px 4px";
    div.style.whiteSpace = "nowrap";
  }

  div.onmouseover = function() { div.style.background="#3d80df"; div.style.color="#fff"; }
  div.onmouseout  = function() { div.style.background=""; div.style.color=""; }
  div.onclick = function()
  {
    var evt = new fan.fwt.Event();
    evt.id = fan.fwt.EventId.action;
    evt.widget = self;

    var list = self.onAction.list();
    for (var i=0; i<list.length; i++) list[i](evt);
  }

  // account for padding/border
  var w = this.size.w - 8;
  var h = this.size.h - 4;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

