//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 May 09  Andy Frank  Creation
//

fan.fwt.SashPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);

fan.fwt.SashPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

fan.fwt.SashPanePeer.prototype.weights$get = function(self) { return this.weights; }
fan.fwt.SashPanePeer.prototype.weights$set = function(self, val) { this.weights = val; }
fan.fwt.SashPanePeer.prototype.weights = null;

fan.fwt.SashPanePeer.prototype.prefSize = function(self, hints)
{
  if (self.orientation == fan.fwt.Orientation.horizontal)
  {
    var max = 0;
    for (var i=0; i<self.kids.length; i++)
    {
      var pref = self.kids[i].prefSize();
      max = Math.max(max, pref.w);
    }
    return fan.gfx.Size.make(max, 10);
  }
  else
  {
    var max = 0;
    for (var i=0; i<self.kids.length; i++)
    {
      var pref = self.kids[i].prefSize();
      max = Math.max(max, pref.h);
    }
    return fan.gfx.Size.make(10, max);
  }
}

fan.fwt.SashPanePeer.prototype.sync = function(self)
{
  if (this.weights != null && this.weights.length != self.kids.length)
    throw new fan.sys.ArgErr.make("weights.size != kids.length");

  if (self.orientation == fan.fwt.Orientation.horizontal)
    this.doHoriz(self);
  else
    this.doVert(self);
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.SashPanePeer.prototype.doHoriz = function(self)
{
  var w = this.size.w;
  var h = this.size.h;
  var wt = this.weights;

  var dy = 0;
  var dh = Math.floor(h /self.kids.length);

  for (var i=0; i<self.kids.length; i++)
  {
    var cw = w;
    var ch = wt==null ? dh : Math.floor(h * (wt[i].valueOf() / 100));

    // if last widget, force to fill remaining space
    if (i == self.kids.length-1) ch = h-dy;

    self.kids[i].pos$set(fan.gfx.Point.make(0, dy));
    self.kids[i].size$set(fan.gfx.Size.make(cw, ch));

    dy += ch;
  }
}

fan.fwt.SashPanePeer.prototype.doVert = function(self)
{
  var w = this.size.w;
  var h = this.size.h;
  var wt = this.weights;

  var dx = 0;
  var dw = Math.floor(w / self.kids.length);

  for (var i=0; i<self.kids.length; i++)
  {
    var cw = wt==null ? dw : Math.floor(w * (wt[i].valueOf() / 100));
    var ch = h;

    // if last widget, force to fill remaining space
    if (i == self.kids.length-1) cw = w-dx;

    self.kids[i].pos$set(fan.gfx.Point.make(dx, 0));
    self.kids[i].size$set(fan.gfx.Size.make(cw, ch));

    dx += cw;
  }
}