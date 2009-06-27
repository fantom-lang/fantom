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
var fwt_TabPanePeer = sys_Obj.$extend(fwt_PanePeer);
fwt_TabPanePeer.prototype.$ctor = function(self) {}

fwt_TabPanePeer.prototype.selectedIndex$get = function(self) { return this.selectedIndex; }
fwt_TabPanePeer.prototype.selectedIndex$set = function(self, val) { this.selectedIndex = val; }
fwt_TabPanePeer.prototype.selectedIndex = null;

fwt_TabPanePeer.prototype.sync = function(self)
{
  fwt_WidgetPeer.prototype.sync.call(this, self);

  var kids = self.kids;
  if (kids.length == 0) return;

  // sync tabs
  var tx = 0;  // tab x pos
  var th = 0;  // tab height
  for (var i=0; i<kids.length; i++)
  {
    var tab = kids[i];
    if (tab.peer.elem == null) return; // not attached yet

    var pref = tab.prefSize();
    tab.pos$set(gfx_Point.make(tx, 0));
    tab.size$set(gfx_Size.make(pref.w, pref.h));

    tx += pref.w + 5;
    th = Math.max(th, pref.h);
  }

  // sync content
  var cw = this.size.w;       // content width
  var ch = this.size.h - th;  // content height
  for (var i=0; i<kids.length; i++)
  {
    var tab = kids[i];
    if (tab.kids.length > 0)
    {
      var sel = this.selectedIndex;
      if (sel == null) sel = 0;

      var x = 0;
      var y = th;
      var w = i == sel ? cw : 0;
      var h = i == sel ? ch : 0;

      var c = tab.kids[0];

      // check if we need to reroot content
      var p = c.peer.elem.parentNode;
      if (p == tab.peer.elem)
      {
        p.removeChild(c.peer.elem);
        this.elem.appendChild(c.peer.elem);
      }

      c.pos$set(gfx_Point.make(x,y));
      c.size$set(gfx_Size.make(w,h));
    }
  }
}