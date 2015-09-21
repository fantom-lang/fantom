//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jun 2011  Andy Frank  Creation
//

/**
 * ToolBarPeer.
 */
fan.fwt.ToolBarPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ToolBarPeer.prototype.$ctor = function(self) {}

fan.fwt.ToolBarPeer.prototype.create = function(parentElem)
{
  var div = this.emptyDiv();
  div.style.background = "#ccc";
  fan.fwt.WidgetPeer.setBg(div, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #d9d9d9, #bbb"));
  div.style.border  = "1px solid #515151";
  div.style.padding = "6px";
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ToolBarPeer.prototype.prefSize = function(self, hints)
{
  var pw = 0;
  var ph = 0;
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid  = kids.get(i);
    var pref = kid.peer.prefSize(kid);
    pw += pref.m_w + 4;
    ph = Math.max(ph, pref.m_h);
  }
  return fan.gfx.Size.make(pw+14, ph+14);  // add padding/border
}

fan.fwt.ToolBarPeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  // sync widget
  this.sync(self);

  // layout button
  var x=6; var y=6;
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid  = kids.get(i);
    var pref = kid.peer.prefSize(kid);
    kid.bounds$(fan.gfx.Rect.make(x, y, pref.m_w, pref.m_h));
    x += pref.m_w + 4;
    kid.peer.relayout(kid);
  }
  return self;
}

fan.fwt.ToolBarPeer.prototype.sync = function(self)
{
  // sync size - account for padding/border
  var w = this.m_size.m_w - 2 - 12;
  var h = this.m_size.m_h - 2 - 12;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}