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

fan.fwt.MenuItemPeer.prototype.selected   = function(self) { return this.m_selected; }
fan.fwt.MenuItemPeer.prototype.selected$  = function(self, val) { this.m_selected = val; }
fan.fwt.MenuItemPeer.prototype.m_selected = false;

fan.fwt.MenuItemPeer.prototype.text   = function(self) { return this.m_text; }
fan.fwt.MenuItemPeer.prototype.text$  = function(self, val) { this.m_text = val; }
fan.fwt.MenuItemPeer.prototype.m_text = "";

fan.fwt.MenuItemPeer.prototype.accelerator   = function(self) { return this.m_accelerator; }
fan.fwt.MenuItemPeer.prototype.accelerator$  = function(self, val) { this.m_accelerator = val; }
fan.fwt.MenuItemPeer.prototype.m_accelerator = null;

fan.fwt.MenuItemPeer.prototype.image   = function(self) { return this.m_image; }
fan.fwt.MenuItemPeer.prototype.image$  = function(self, val) { this.m_image = val; }
fan.fwt.MenuItemPeer.prototype.m_image = null;

fan.fwt.MenuItemPeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  div.style.font = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
  div.style.cursor = "default";
  div.style.padding = "1px 4px";
  div.style.whiteSpace = "nowrap";

  div.onmouseover = function()
  {
    if (!self.peer.m_enabled) return;
    div.style.background = "#3d80df";
    div.style.color = "#fff";
  }

  div.onmouseout = function()
  {
    if (!self.peer.m_enabled) return;
    div.style.background = "";
    div.style.color = "";
  }

  div.onclick = function()
  {
    if (!self.peer.m_enabled) return;

    var evt = fan.fwt.Event.make();
    evt.id = fan.fwt.EventId.m_action;
    evt.widget = self;

    var list = self.m_onAction.list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);
  }

  parentElem.appendChild(div);
  return div;
}

fan.fwt.MenuItemPeer.prototype.sync = function(self)
{
  var div = this.elem;

  // remove old text node
  while (div.firstChild != null)
  {
    var child = div.firstChild;
    div.removeChild(child);
    child = null;
    delete child;
  }

  // add new text node
  div.appendChild(document.createTextNode(this.m_text));

  // sync state
  div.style.color = self.peer.m_enabled ? "#000" : "#999";

  // account for padding/border
  var w = this.m_size.m_w - 8;
  var h = this.m_size.m_h - 4;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

