//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 May 09  Andy Frank  Creation
//

var fwt_SashPanePeer = sys_Obj.$extend(fwt_PanePeer);

fwt_SashPanePeer.prototype.$ctor = function(self)
{
  fwt_PanePeer.prototype.$ctor.call(this, self);
}

fwt_SashPanePeer.prototype.weights$get = function(self) { return this.weights; }
fwt_SashPanePeer.prototype.weights$set = function(self, val) { this.weights = val; }
fwt_SashPanePeer.prototype.weights = null;

fwt_SashPanePeer.prototype.sync = function(self)
{
  var w = this.size.w;
  var h = this.size.h;

  var dy = 0;
  var dh = Math.floor(h /self.kids.length);

  for (var i=0; i<self.kids.length; i++)
  {
    var cw = w;
    var ch = (i<self.kids.length-1) ? dh : h-dy; // give last widget leftovers

    self.kids[i].pos$set(gfx_Point.make(0, dy));
    self.kids[i].size$set(gfx_Size.make(cw, ch));

    dy += ch;
  }

  fwt_WidgetPeer.prototype.sync.call(this, self);
}