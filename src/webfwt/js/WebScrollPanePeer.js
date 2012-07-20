//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 10  Andy Frank  Creation
//

/**
 * WebScrollPanePeer.
 */
fan.webfwt.WebScrollPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.WebScrollPanePeer.prototype.$ctor = function(self)
{
  this.hasScrollListener = false;
}

// css
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_WebScrollPane_ { "+
  " border:1px solid #9f9f9f;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar {" +
  " width: 10px;" +
  " height: 10px;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar:vertical {" +
  " border-left: 1px solid #bbb;" +
  " background: -webkit-gradient(linear, left top, right top, from(#eee), to(#ddd));" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar:horizontal {" +
  " border-top: 1px solid #bbb;" +
  " background: -webkit-gradient(linear, left top, left bottom, from(#eee), to(#ddd));" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-track-piece:vertical {" +
  " background: -webkit-gradient(linear, left top, right top, from(#eaeaea), to(#f8f8f8));" +
  " background: -webkit-box-shadow (linear, left top, right top, from(#eaeaea), to(#f8f8f8));" +
  " margin: 5px 0;" +
  " border: 1px solid #bbb;" +
  " border-right-color: #ddd;" +
  " border-radius: 5px;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-track-piece:horizontal {" +
  " background: -webkit-gradient(linear, left top, left bottom, from(#eaeaea), to(#f8f8f8));" +
  " background: -webkit-box-shadow (linear, left top, left bottom, from(#eaeaea), to(#f8f8f8));" +
  " margin: 0 5px;" +
  " border: 1px solid #bbb;" +
  " border-bottom-color: #ddd;" +
  " border-radius: 5px;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-button {" +
  " display:none;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-thumb {" +
  " border: 1px solid #848fa6;" +
  " border-radius: 5px;" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-thumb:vertical {" +
  " background: -webkit-gradient(linear, left top, right top, from(#b5bfcd), to(#8b99b2));" +
  "}" +
  "div._webfwt_WebScrollPane_::-webkit-scrollbar-thumb:horizontal {" +
  " background: -webkit-gradient(linear, left top, left bottom, from(#b5bfcd), to(#8b99b2));" +
  "}");

fan.webfwt.WebScrollPanePeer.prototype.create = function(parentElem, self)
{
  var overx = "hidden";
  switch (self.m_hpolicy)
  {
    case fan.webfwt.WebScrollPane.m_on:   overx = "scroll"; break;
    case fan.webfwt.WebScrollPane.m_auto: overx = "auto"; break;
  }

  var overy = "hidden";
  switch (self.m_vpolicy)
  {
    case fan.webfwt.WebScrollPane.m_on:   overy = "scroll"; break;
    case fan.webfwt.WebScrollPane.m_auto: overy = "auto"; break;
  }

  var div = this.emptyDiv();
  div.className = "_webfwt_WebScrollPane_";
  div.style.background = self.bg().toCss();
  div.style.overflowX = overx;
  div.style.overflowY = overy;
  if (self.m_border != null)
    div.style.border = "1px solid " + self.m_border.toCss();
  parentElem.appendChild(div);
  return div;
}

fan.webfwt.WebScrollPanePeer.prototype.sync = function(self)
{
  // check events
  this.checkScrollListener(self);

  // account for border
  var w = this.m_size.m_w - 2;
  var h = this.m_size.m_h - 2;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}


fan.webfwt.WebScrollPanePeer.prototype.checkScrollListener = function(self)
{
  if (this.hasScrollListener) return;     // already added
  if (self.onScroll().isEmpty()) return;  // nothing to add yet

  // attach and mark attached
  var peer = this;
  var func = function(e)
  {
    // scroll pos
    var sx = peer.scrollX(self);
    var sy = peer.scrollY(self);

    // create fwt::Event and invoke handler
    var evt = fan.fwt.Event.make();
    evt.m_id  = fan.fwt.EventId.m_unknown;
    evt.m_pos = fan.gfx.Point.make(sx, sy);
    evt.m_widget = self;

    // invoke handlers
    var list = self.onScroll().list();
    for (var i=0; i<list.m_size; i++)
    {
      list.get(i).call(evt);
      if (evt.m_consumed) break;
    }
  }

  // attach event handler
  this.elem.addEventListener("scroll", func, false);
  this.hasScrollListener = true;
}

// TODO FIXIT: animate
fan.webfwt.WebScrollPanePeer.prototype.scrollToTop    = function(self) { this.elem.scrollTop = 0; }
fan.webfwt.WebScrollPanePeer.prototype.scrollToBottom = function(self) { this.elem.scrollTop = this.elem.scrollHeight; }
fan.webfwt.WebScrollPanePeer.prototype.scrollToLeft   = function(self) { this.elem.scrollLeft = 0; }
fan.webfwt.WebScrollPanePeer.prototype.scrollToRight  = function(self) { this.elem.scrollLeft = this.elem.scrollWidth; }

fan.webfwt.WebScrollPanePeer.prototype.scrollX = function(self) { return this.elem.scrollLeft; }
fan.webfwt.WebScrollPanePeer.prototype.scrollY = function(self) { return this.elem.scrollTop;  }
