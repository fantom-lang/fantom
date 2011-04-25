//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 09  Andy Frank  Creation
//

/**
 * ScrollBarPeer.
 */
fan.fwt.ScrollBarPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ScrollBarPeer.prototype.$ctor = function(self) {}

fan.fwt.ScrollBarPeer.prototype.val   = function(self) { return this.m_val; }
fan.fwt.ScrollBarPeer.prototype.val$  = function(self, val)
{
  if (val < 0) val = 0;
  if (val > this.m_max) val = this.m_max;
  this.m_val = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.ScrollBarPeer.prototype.m_val = 0;

fan.fwt.ScrollBarPeer.prototype.min   = function(self) { return this.m_min; }
fan.fwt.ScrollBarPeer.prototype.min$  = function(self, val)
{ 
  if (val < 0 || val >= this.m_max) return;
  this.m_min = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.ScrollBarPeer.prototype.m_min = 0;

fan.fwt.ScrollBarPeer.prototype.max   = function(self) { return this.m_max; }
fan.fwt.ScrollBarPeer.prototype.max$  = function(self, val) 
{ 
  if (val < 0 || val <= this.m_min) return;
  this.m_max = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.ScrollBarPeer.prototype.m_max = 100;

fan.fwt.ScrollBarPeer.prototype.thumb  = function(self) { return this.m_thumb; }
fan.fwt.ScrollBarPeer.prototype.thumb$ = function(self, val)
{
  this.m_thumb = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.ScrollBarPeer.prototype.m_thumb = 10;

// not supported
fan.fwt.ScrollBarPeer.prototype.page   = function(self) { return this.m_page; }
fan.fwt.ScrollBarPeer.prototype.page$  = function(self, val) { this.m_page = val; } 
fan.fwt.ScrollBarPeer.prototype.m_page = 10;

fan.fwt.ScrollBarPeer.prototype.prefSize = function(self, hints)
{
  var pref = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
  var thickness = fan.fwt.ScrollBarPeer.thickness();
  if (self.m_orientation == fan.gfx.Orientation.m_horizontal)
    return fan.gfx.Size.make(pref.m_w, thickness);
  else
    return fan.gfx.Size.make(thickness, pref.m_h);
}

fan.fwt.ScrollBarPeer.prototype.create = function(parentElem, self)
{
  var scrollDiv = document.createElement("div");
  scrollDiv.style.padding = "0px";       
  var scrollContent = document.createElement("div");
  scrollDiv.appendChild(scrollContent);

  var vertical = self.m_orientation == fan.gfx.Orientation.m_vertical;
  if (vertical)
  {
    scrollDiv.style.width = fan.fwt.ScrollBarPeer.thickness() + "px";
    scrollDiv.style.overflowX = "hidden";
    scrollDiv.style.overflowY = "scroll";
    scrollContent.style.width = "1px";
  }
  else
  {
    scrollDiv.style.height = fan.fwt.ScrollBarPeer.thickness() + "px";
    scrollDiv.style.overflowX = "scroll";
    scrollDiv.style.overflowY = "hidden";
    scrollContent.style.height = "1px";
  }

  scrollDiv.onscroll = function(event)
  { 
    var scrollIndent = 0;
    var scrollSize = 0;
    if (self.m_orientation == fan.gfx.Orientation.m_horizontal)
    {
      scrollSize = scrollDiv.scrollWidth - scrollDiv.clientWidth;
      scrollIndent = scrollDiv.scrollLeft;
    }  
    else
    {
      scrollSize = scrollDiv.scrollHeight - scrollDiv.clientHeight;
      scrollIndent = scrollDiv.scrollTop;
    }
    var peer = self.peer;
    var newVal = Math.round(peer.m_min + scrollIndent * (peer.m_max - peer.m_min - peer.m_thumb) / scrollSize);
    if (peer.m_val == newVal)
      return

    peer.m_val = newVal;
    // fire onModify
    if (self.m_onModify.size() > 0)
    {
      var me = fan.fwt.Event.make();
      me.m_id = fan.fwt.EventId.m_modified;
      me.m_widget = self;
      var list = self.m_onModify.list();
      for (var i=0; i<list.size(); i++) list.get(i).call(me);
    }
  }

  // container element
  var div = this.emptyDiv();
  div.appendChild(scrollDiv);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ScrollBarPeer.prototype.sync = function(self)
{
  var vert = self.m_orientation == fan.gfx.Orientation.m_vertical;
  var w = this.m_size.m_w;
  var h = this.m_size.m_h;
  var scrollDiv = this.elem.firstChild;
  var scrollContent = scrollDiv.firstChild;

  var maxRatio = (this.m_max - this.m_min) / this.m_thumb;
  var valRatio = (this.m_val - this.m_min) / this.m_thumb;

  if (vert)
  {
    scrollDiv.style.height = h + "px";
    if (this.m_enabled)
    {
      scrollContent.style.height = Math.round(h * maxRatio) + "px";
      scrollDiv.scrollTop = Math.round(h * valRatio);
    }
    else
    {
      scrollDiv.scrollTop = 0;
      scrollContent.style.height = "0px";
    }
  }
  else
  {
    scrollDiv.style.width = w + "px";
    if (this.m_enabled)
    {
      scrollContent.style.width = Math.round(w * maxRatio) + "px";
      scrollDiv.scrollLeft = Math.round(w * valRatio);
    }
    else
    {
      scrollDiv.scrollLeft = 0;
      scrollContent.style.width = "0px";
    }
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.ScrollBarPeer.prototype.checkModifyListeners = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.fwt.ScrollBarPeer.thickness = function()
{
  if (fan.fwt.ScrollBarPeer.m_thickness == 0)
  {
    var inner = document.createElement('div');
    inner.style.height = "100px";

    var outer = document.createElement('div');
    with (outer.style)
    {
      width = "50px"; height = "50px";
      overflow = "hidden"; position = "absolute";
      visibility = "hidden";
    }
    outer.appendChild(inner);

    document.body.appendChild(outer);
    var w1 = inner.offsetWidth;
    outer.style.overflow = 'scroll';
    var w2 = inner.offsetWidth;
    if (w1 == w2) w2 = outer.clientWidth;
    document.body.removeChild(outer);

    fan.fwt.ScrollBarPeer.m_thickness = (w1 - w2);
  }
  return fan.fwt.ScrollBarPeer.m_thickness;
}

fan.fwt.ScrollBarPeer.m_thickness = 0;
