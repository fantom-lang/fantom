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

// see init.js for CSS

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
  if (self.m_mode == fan.fwt.MenuItemMode.m_sep) div.className += " sep";

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
  if (self.m_mode == fan.fwt.MenuItemMode.m_sep) self.peer.m_enabled = false;
  else
  {
    if (this.m_image != null)
    {
      var img = document.createElement("img");
      img.src = fan.fwt.WidgetPeer.uriToImageSrc(this.m_image.m_uri);
      div.appendChild(img);
    }
    div.appendChild(document.createTextNode(this.m_text));
  }

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

