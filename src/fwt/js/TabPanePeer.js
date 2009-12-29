//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jun 09  Andy Frank  Creation
//

/**
 * TabPanePeer.
 */
fan.fwt.TabPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.fwt.TabPanePeer.prototype.$ctor = function(self) {}

fan.fwt.TabPanePeer.prototype.selectedIndex = function(self) { return this.m_selectedIndex; }
fan.fwt.TabPanePeer.prototype.selectedIndex$ = function(self, val) { this.m_selectedIndex = val; }
fan.fwt.TabPanePeer.prototype.m_selectedIndex = 0;

fan.fwt.TabPanePeer.prototype.sync = function(self)
{
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);

  var kids = self.m_kids;
  if (kids.size() == 0) return;

  // sync tabs
  var tx = 12;  // tab x pos
  var th = 0;   // tab height
  for (var i=0; i<kids.size(); i++)
  {
    var tab = kids.get(i);
    if (tab.peer.elem == null) return; // not attached yet

    var pref = tab.prefSize();
    tab.pos$(fan.gfx.Point.make(tx, 0));
    tab.size$(fan.gfx.Size.make(pref.m_w, pref.m_h));
    tab.peer.index = i;

    tx += pref.m_w + 3;
    th = Math.max(th, pref.m_h);
  }

  // content border
  if (this.contentBorder == null)
  {
    var cb = document.createElement("div");
    this.elem.insertBefore(cb, this.elem.firstChild);
    this.contentBorder = cb;
  }
  with (this.contentBorder.style)
  {
    background = "#eee";
    border     = "1px solid #404040";
    position   = "absolute";
    left   = 0;
    top    = (th-1) + "px";
    width  = (this.m_size.m_w-2) + "px";
    height = (this.m_size.m_h-th-1) + "px";
  }

  // sync content
  var cw = this.m_size.m_w;       // content width
  var ch = this.m_size.m_h - th;  // content height
  for (var i=0; i<kids.size(); i++)
  {
    var tab = kids.get(i);
    if (tab.m_kids.size() > 0)
    {
      var s = i == this.m_selectedIndex;
      var x = 12;
      var y = 12 + th;
      var w = s ? cw-24 : 0;
      var h = s ? ch-24 : 0;

      var c = tab.m_kids.get(0);

      // check if we need to re-root content
      if (c.peer.elem.parentNode == null)
        this.elem.appendChild(c.peer.elem);

      c.pos$(fan.gfx.Point.make(x,y));
      c.size$(fan.gfx.Size.make(w,h));
    }
  }
}