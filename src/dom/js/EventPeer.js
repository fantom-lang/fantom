//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//    8 Jul 2009  Andy Frank  Split webappClient into sys/dom
//   26 Aug 2015  Andy Frank  Rename back to Event
//

fan.dom.EventPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.EventPeer.prototype.$ctor = function(self) {}

fan.dom.EventPeer.prototype.target = function(self)
{
  return fan.dom.ElemPeer.wrap(this.event.target);
}

fan.dom.EventPeer.prototype.x = function(self) { return this.event.pageX; }
fan.dom.EventPeer.prototype.y = function(self) { return this.event.pageY; }

fan.dom.EventPeer.prototype.alt   = function(self) { return this.event.altKey; }
fan.dom.EventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
fan.dom.EventPeer.prototype.shift = function(self) { return this.event.shiftKey; }
fan.dom.EventPeer.prototype.meta  = function(self) { return this.event.metaKey; }

fan.dom.EventPeer.prototype.button = function(self) { return this.event.button; }
fan.dom.EventPeer.prototype.keyCode = function(self) { return this.event.keyCode; }

fan.dom.EventPeer.prototype.stop = function(self)
{
  this.event.preventDefault();
  this.event.stopPropagation();
}

fan.dom.EventPeer.prototype.dataTransfer = function(self)
{
  // Andy Frank 19-Jun-2015 -- Chrome/WebKit do not allow reading getData during
  // the dragover event - which makes it impossible to check drop targets during
  // drag.  To workaround for now - we just cache in a static field

  if (this.event.dataTransfer.types &&
      this.event.dataTransfer.types.length > 0 &&
      this.event.dataTransfer.getData(this.event.dataTransfer.types[0]) == "")
    return fan.dom.EventPeer.lastDataTx;

  if (!this.dataTx)
    this.dataTx = fan.dom.EventPeer.lastDataTx = fan.dom.DataTransferPeer.make(this.event.dataTransfer);

  return this.dataTx;
}

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