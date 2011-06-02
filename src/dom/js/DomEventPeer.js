//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.DomEventPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.DomEventPeer.prototype.$ctor = function(self) {}

fan.dom.DomEventPeer.prototype.target = function(self)
{
  return fan.dom.ElemPeer.make(this.event.target);
}

fan.dom.DomEventPeer.prototype.x = function(self) { return this.event.pageX; }
fan.dom.DomEventPeer.prototype.y = function(self) { return this.event.pageY; }

fan.dom.DomEventPeer.prototype.alt   = function(self) { return this.event.altKey; }
fan.dom.DomEventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
fan.dom.DomEventPeer.prototype.shift = function(self) { return this.event.shiftKey; }

fan.dom.DomEventPeer.prototype.button = function(self) { return this.event.button; }

fan.dom.DomEventPeer.prototype.toStr = function(self)
{
  return "DomEvent[" +
    "target:" + this.target() +
    ", x:" + this.x() + ", y:" + this.y() +
    ", alt:" + this.alt() + ", ctrl:" + this.ctrl() + ", shift:" + this.shift() +
    ", button:" + this.button() +
    "]";
}

fan.dom.DomEventPeer.make = function(event)
{
  var x = fan.dom.DomEvent.make();
  x.peer.event = event;
  return x;
}