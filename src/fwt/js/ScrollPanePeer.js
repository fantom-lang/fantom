//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 10  Andy Frank  Creation
//

/**
 * ScrollPanePeer.
 */
fan.fwt.ScrollPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.fwt.ScrollPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

fan.fwt.ScrollPanePeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  div.style.overflow = "auto";
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ScrollPanePeer.prototype.setMinSize = function(self, s)
{
  this.m_minSize = s;
}

fan.fwt.ScrollPanePeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var c = self.m_content;
  if (c != null)
  {
    var sz = this.m_size;
    var ms = this.m_minSize;
    var w = (sz.m_w < ms.m_w) ? ms.m_w : sz.m_w;
    var h = (sz.m_h < ms.m_h) ? ms.m_h : sz.m_h;
    c.size$(fan.gfx.Size.make(w,h));
    c.peer.relayout(c);
  }

  return self;
}