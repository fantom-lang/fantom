//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.EventPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.EventPeer.prototype.$ctor = function(self) {}

fan.dom.EventPeer.prototype.target = function(self)
{
  return fan.dom.ElemPeer.make(this.event.target);
}

fan.dom.EventPeer.prototype.x = function(self) { return this.event.pageX; }
fan.dom.EventPeer.prototype.y = function(self) { return this.event.pageY; }

fan.dom.EventPeer.prototype.alt   = function(self) { return this.event.altKey; }
fan.dom.EventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
fan.dom.EventPeer.prototype.shift = function(self) { return this.event.shiftKey; }

fan.dom.EventPeer.prototype.button = function(self) { return this.event.button; }

fan.dom.EventPeer.prototype.toStr = function(self)
{
  return "Event[" +
    "target:" + this.target() +
    ", x:" + this.x() + ", y:" + this.y() +
    ", alt:" + this.alt() + ", ctrl:" + this.ctrl() + ", shift:" + this.shift() +
    ", button:" + this.button() +
    "]";
}

fan.dom.EventPeer.make = function(event)
{
  var x = fan.dom.Event.make();
  x.peer.event = event;
  return x;
}