//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

var dom_EventPeer = sys_Obj.$extend(sys_Obj);

dom_EventPeer.prototype.$ctor = function(self) {}

dom_EventPeer.prototype.target = function(self)
{
  return dom_ElemPeer.make(this.event.target);
}

dom_EventPeer.prototype.x = function(self) { return this.event.pageX; }
dom_EventPeer.prototype.y = function(self) { return this.event.pageY; }

dom_EventPeer.prototype.alt   = function(self) { return this.event.altKey; }
dom_EventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
dom_EventPeer.prototype.shift = function(self) { return this.event.shiftKey; }

dom_EventPeer.prototype.toStr = function(self)
{
  return "Event[" +
    "target:" + this.target() +
    ", x:" + this.x() + ", y:" + this.y() +
    ", alt:" + this.alt() + ", ctrl:" + this.ctrl() + ", shift:" + this.shift() +
    "]";
}

dom_EventPeer.make = function(self, event)
{
  var wrap = new dom_EventPeer();
  if (event != null) wrap.event = event;
  return wrap;
}