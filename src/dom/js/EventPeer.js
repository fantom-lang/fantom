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

fan.dom.EventPeer.prototype.type = function(self) { return this.event.type; }

fan.dom.EventPeer.prototype.target = function(self)
{
  if (this.$target == null)
    this.$target = fan.dom.ElemPeer.wrap(this.event.target);
  return this.$target;
}

fan.dom.EventPeer.prototype.pagePos = function(self)
{
  if (this.$pagePos == null)
    this.$pagePos = fan.graphics.Point.makeInt(this.event.pageX, this.event.pageY);
  return this.$pagePos;
}

fan.dom.EventPeer.prototype.alt   = function(self) { return this.event.altKey; }
fan.dom.EventPeer.prototype.ctrl  = function(self) { return this.event.ctrlKey; }
fan.dom.EventPeer.prototype.shift = function(self) { return this.event.shiftKey; }
fan.dom.EventPeer.prototype.meta  = function(self) { return this.event.metaKey; }

fan.dom.EventPeer.prototype.button = function(self) { return this.event.button; }
fan.dom.EventPeer.prototype.key = function(self) { return this.$key }

fan.dom.EventPeer.prototype.delta = function(self)
{
  if (this.$delta == null)
  {
    this.$delta = this.event.deltaX != null && this.event.deltaY != null
      ? fan.graphics.Point.makeInt(this.event.deltaX, this.event.deltaY)
      : fan.graphics.Point.m_defVal;
  }
  return this.$delta;
}

fan.dom.EventPeer.prototype.err = function(self)
{
  if (this.event.error == null) return null;
  if (this.$err == null) this.$err = fan.sys.Err.make(this.event.error);
  return this.$err;
}

fan.dom.EventPeer.prototype.stop = function(self)
{
  this.event.preventDefault();
  this.event.stopPropagation();
  this.event.cancelBubble = true;
  this.event.returnValue = false;
}

fan.dom.EventPeer.prototype.get = function(self, name, def)
{
  var val = this.event[name];
  if (val != null) return val;
  if (def != null) return def;
  return null;
}

fan.dom.EventPeer.prototype.set = function(self, name, val)
{
  this.elem[name] = val;
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

fan.dom.EventPeer.make = function(event)
{
  var x = fan.dom.Event.make();
  x.peer.event = event;
  if (event.keyCode) x.peer.$key = fan.dom.Key.fromCode(event.keyCode);
  return x;
}