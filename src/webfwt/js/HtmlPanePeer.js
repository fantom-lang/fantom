//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 09  Andy Frank  Creation
//

fan.webfwt.HtmlPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.HtmlPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

fan.webfwt.HtmlPanePeer.prototype.m_html = ""
fan.webfwt.HtmlPanePeer.prototype.html = function(self) { return this.m_html; }
fan.webfwt.HtmlPanePeer.prototype.html$ = function(self, val)
{
  this.m_html = val;
  this.needRebuild = true;
}

fan.webfwt.HtmlPanePeer.prototype.create = function(parentElem, self)
{
  var fixw = self.m_width > 0;
  var html = document.createElement("div");
  if (fixw) html.style.width = self.m_width + "px";

  if (self.m_font != null) html.style.font = fan.fwt.WidgetPeer.fontToCss(self.m_font);
  if (self.m_fg   != null) html.style.color = self.m_fg.toCss();

  var div = this.emptyDiv();
  div.style.font = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
  if (!fixw) div.style.overflow = "auto";
  div.appendChild(html);
  parentElem.appendChild(div);
  return div;
}

fan.webfwt.HtmlPanePeer.prototype.needRebuild = true;
fan.webfwt.HtmlPanePeer.prototype.rebuild = function(self)
{
  this.needRebuild = true;
  self.relayout();
}

fan.webfwt.HtmlPanePeer.prototype.sync = function(self)
{
  if (this.needRebuild)
  {
    this.elem.firstChild.innerHTML = this.m_html;
    this.needRebuild = false;
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.webfwt.HtmlPanePeer.prototype.prefSize = function(self, hints)
{
  return fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
}