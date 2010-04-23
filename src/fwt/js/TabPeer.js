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
fan.fwt.TabPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TabPeer.prototype.$ctor = function(self) {}

fan.fwt.TabPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.TabPeer.prototype.text$ = function(self, val) { this.m_text = val; }
fan.fwt.TabPeer.prototype.m_text = "";

fan.fwt.TabPeer.prototype.image = function(self) { return this.m_image; }
fan.fwt.TabPeer.prototype.image$ = function(self, val)
{
  this.m_image = val;
  fan.fwt.FwtEnvPeer.loadImage(val, self)
}
fan.fwt.TabPeer.prototype.m_image = null;

fan.fwt.TabPeer.prototype.sync = function(self)
{
  var elem = this.elem;
  var selected = this.index == self.m_parent.peer.m_selectedIndex;

  while (elem.firstChild != null) elem.removeChild(elem.firstChild);
  var text = document.createTextNode(this.m_text);
  elem.appendChild(text);

  var $self = self;
  elem.onmousedown = function()
  {
    $self.m_parent.peer.m_selectedIndex = $self.peer.index;
    $self.m_parent.relayout();
  }

  var css = elem.style;
  css.cursor  = "default";
  css.padding = "6px 12px";
  css.border  = "1px solid #404040";
  css.font = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
  if (selected) css.borderBottom = "1px solid #eee";
  css.MozBorderRadius = "5px 5px 0 0";
  css.webkitBorderTopLeftRadius  = "5px";
  css.webkitBorderTopRightRadius = "5px";

  if (selected)
  {
    fan.fwt.WidgetPeer.setBg(elem, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #f8f8f8, #eee"));
  }
  else
  {
    fan.fwt.WidgetPeer.setBg(elem, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #eee, #ccc"));
  }

  // account for border/padding
  var w = this.m_size.m_w - 26;
  var h = this.m_size.m_h - 14;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

// index of tab in TabPane
fan.fwt.TabPeer.prototype.index = null;