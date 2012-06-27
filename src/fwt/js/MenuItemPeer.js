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

// CSS
fan.fwt.WidgetPeer.addCss(
  "div._fwt_MenuItem_ {" +
  "  font:" + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont) + ";" +
  " padding: 2px 12px 0px 12px;" +
  " white-space: nowrap;" +
  " -webkit-box-sizing: border-box;" +
  "    -moz-box-sizing: border-box;" +
  "         box-sizing: border-box;" +
  "}" +
  "div._fwt_MenuItem_.disabled {" +
  " color: #999;" +
  "}" +
  "div._fwt_MenuItem_:hover," +
  "div._fwt_MenuItem_:focus {" +
  " background: #3d80df;" +
  " color: #fff;" +
  "}" +
  "div._fwt_MenuItem_.disabled:hover {" +
  " background: none;" +
  " color: #999;" +
  "}");

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

fan.fwt.MenuItemPeer.prototype.m_$defCursor = "default";

fan.fwt.MenuItemPeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  div.className = "_fwt_MenuItem_";

  var $this = this;
  div.onclick = function() { $this.invoke(self); }

  parentElem.appendChild(div);
  return div;
}

fan.fwt.MenuItemPeer.prototype.invoke = function(self)
{
  if (!self.peer.m_enabled) return;

  var evt = fan.fwt.Event.make();
  evt.id = fan.fwt.EventId.m_action;
  evt.widget = self;

  var list = self.onAction().list();
  for (var i=0; i<list.size(); i++) list.get(i).call(evt);
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
  if (self.peer.m_enabled)
  {
    fan.fwt.WidgetPeer.removeClassName(div, "disabled")
    div.tabIndex = 0;
  }
  else
  {
    fan.fwt.WidgetPeer.addClassName(div, "disabled")
    div.tabIndex = -1;
  }

  // sync
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

