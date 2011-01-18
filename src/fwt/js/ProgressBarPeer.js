//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jan 11  Andy Frank  Creation
//

/**
 * ProgressBarPeer.
 */
fan.fwt.ProgressBarPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ProgressBarPeer.prototype.$ctor = function(self) {}

fan.fwt.ProgressBarPeer.prototype.m_val = 0;
fan.fwt.ProgressBarPeer.prototype.val = function(self) { return this.m_val; }
fan.fwt.ProgressBarPeer.prototype.val$ = function(self, val)
{
  this.m_val = val;
  this.updateMeter();
}

fan.fwt.ProgressBarPeer.prototype.m_min = 0;
fan.fwt.ProgressBarPeer.prototype.min = function(self) { return this.m_min; }
fan.fwt.ProgressBarPeer.prototype.min$ = function(self, val) { this.m_min = val; }

fan.fwt.ProgressBarPeer.prototype.m_max = 100;
fan.fwt.ProgressBarPeer.prototype.max = function(self) { return this.m_max; }
fan.fwt.ProgressBarPeer.prototype.max$ = function(self, val) { this.m_max = val; }

fan.fwt.ProgressBarPeer.prototype.create = function(parentElem, self)
{
  var meter = this.emptyDiv();
  var s = meter.style;
  s.background   = "#3d80df";
  s.border       = "1px solid #326cbf";
  s.borderRadius = "7px";
  s.webkitBoxShadow = "inset #689de8 0px 1px 1px";
  this.meter = meter;

  var bar = this.emptyDiv();
  s = bar.style;
  s.background   = "white";
  s.border       = "1px solid #ccc";
  s.borderRadius = "7px";
  s.webkitBoxShadow = "inset #e5e5e5 0px 1px 2px, rgba(255,255,255,0.5) 0px 1px 1px";
  this.bar = bar;

  var div = this.emptyDiv();
  div.appendChild(bar);
  div.appendChild(meter);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ProgressBarPeer.prototype.updateMeter = function()
{
  if (this.meter)
  {
    var per = this.m_val / (this.m_max - this.m_min);
    var pw  = Math.floor(per * (this.m_size.m_w-2));
    if (pw < 12) pw = 12;
    this.meter.style.width = pw + "px";
  }
}

fan.fwt.ProgressBarPeer.prototype.prefSize = function(hints)
{
  return fan.gfx.Size.make(300, 16);
}

fan.fwt.ProgressBarPeer.prototype.sync = function(self)
{
  // account for padding/border
  var w = this.m_size.m_w-2;
  var h = this.m_size.m_h-3;

  // sync meter and bar
  this.updateMeter();
  this.meter.style.height = h + "px";
  this.bar.style.width    = w + "px";
  this.bar.style.height   = h + "px";

  // sync widget
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}
