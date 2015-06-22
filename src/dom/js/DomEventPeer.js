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
  return fan.dom.ElemPeer.wrap(this.event.target);
}

fan.dom.DomEventPeer.prototype.x = function(self) { return this.event.pageX; }
fan.dom.DomEventPeer.prototype.y = function(self) { return this.event.pageY; }

fan.dom.DomEventPeer.prototype.alt   = function(self) { return this.event.altKey; }
fan.dom.DomEventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
fan.dom.DomEventPeer.prototype.shift = function(self) { return this.event.shiftKey; }
fan.dom.DomEventPeer.prototype.meta  = function(self) { return this.event.metaKey; }

fan.dom.DomEventPeer.prototype.button = function(self) { return this.event.button; }
fan.dom.DomEventPeer.prototype.keyCode = function(self) { return this.event.keyCode; }

fan.dom.DomEventPeer.prototype.stop = function(self)
{
  this.event.preventDefault();
  this.event.stopPropagation();
}

fan.dom.DomEventPeer.prototype.dataTransfer = function(self)
{
  // Andy Frank 19-Jun-2015 -- Chrome/WebKit do not allow reading getData during
  // the dragover event - which makes it impossible to check drop targets during
  // drag.  To workaround for now - we just cache in a static field

  if (this.event.dataTransfer.types &&
      this.event.dataTransfer.types.length > 0 &&
      this.event.dataTransfer.getData(this.event.dataTransfer.types[0]) == "")
    return fan.dom.DomEventPeer.lastDataTx;

  if (!this.dataTx)
    this.dataTx = fan.dom.DomEventPeer.lastDataTx = fan.dom.DataTransferPeer.make(this.event.dataTransfer);

  return this.dataTx;
}

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