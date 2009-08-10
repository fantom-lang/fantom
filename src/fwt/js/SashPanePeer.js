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

fan.fwt.SashPanePeer.prototype.weights   = function(self) { return this.m_weights; }
fan.fwt.SashPanePeer.prototype.weights$  = function(self, val) { this.m_weights = val; }
fan.fwt.SashPanePeer.prototype.m_weights = null;

fan.fwt.SashPanePeer.prototype.prefSize = function(self, hints)
{
  if (self.m_orientation == fan.gfx.Orientation.m_horizontal)
  {
    var max = 0;
    for (var i=0; i<self.m_kids.length; i++)
    {
      var pref = self.m_kids[i].prefSize();
      max = Math.max(max, pref.m_w);
    }
    return fan.gfx.Size.make(max, 10);
  }
  else
  {
    var max = 0;
    for (var i=0; i<self.m_kids.length; i++)
    {
      var pref = self.m_kids[i].prefSize();
      max = Math.max(max, pref.m_h);
    }
    return fan.gfx.Size.make(10, max);
  }
}

fan.fwt.SashPanePeer.prototype.sync = function(self)
{
  if (this.m_weights != null && this.m_weights.length != self.m_kids.length)
    throw new fan.sys.ArgErr.make("weights.size != kids.length");

  if (self.m_orientation == fan.gfx.Orientation.m_horizontal)
    this.doHoriz(self);
  else
    this.doVert(self);
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.SashPanePeer.prototype.doHoriz = function(self)
{
  var w  = this.m_size.m_w;
  var h  = this.m_size.m_h;
  var wt = this.m_weights;

  var dy = 0;
  var dh = Math.floor(h /self.m_kids.length);

  for (var i=0; i<self.m_kids.length; i++)
  {
    var cw = w;
    var ch = wt==null ? dh : Math.floor(h * (wt[i].valueOf() / 100));

    // if last widget, force to fill remaining space
    if (i == self.m_kids.length-1) ch = h-dy;

    self.m_kids[i].pos$(fan.gfx.Point.make(0, dy));
    self.m_kids[i].size$(fan.gfx.Size.make(cw, ch));

    dy += ch;
  }
}

fan.fwt.SashPanePeer.prototype.doVert = function(self)
{
  var w  = this.m_size.m_w;
  var h  = this.m_size.m_h;
  var wt = this.m_weights;

  var dx = 0;
  var dw = Math.floor(w / self.m_kids.length);

  for (var i=0; i<self.m_kids.length; i++)
  {
    var cw = wt==null ? dw : Math.floor(w * (wt[i].valueOf() / 100));
    var ch = h;

    // if last widget, force to fill remaining space
    if (i == self.m_kids.length-1) cw = w-dx;

    self.m_kids[i].pos$(fan.gfx.Point.make(dx, 0));
    self.m_kids[i].size$(fan.gfx.Size.make(cw, ch));

    dx += cw;
  }
}