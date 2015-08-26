//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 2015  Andy Frank  Creation
//

fan.dom.DataTransferPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.DataTransferPeer.prototype.$ctor = function(self) {}

fan.dom.DataTransferPeer.prototype.dropEffect = function(self) { return this.dataTx.dropEffect; }
fan.dom.DataTransferPeer.prototype.dropEffect$ = function(self, val) { this.dataTx.dropEffect = val; }

fan.dom.DataTransferPeer.prototype.effectAllowed = function(self) { return this.dataTx.effectAllowed; }
fan.dom.DataTransferPeer.prototype.effectAllowed$ = function(self, val) { this.dataTx.effectAllowed = val; }

fan.dom.DataTransferPeer.prototype.types = function(self)
{
  var list = fan.sys.List.make(fan.sys.Str.$type);
  for (var i=0; i<this.dataTx.types.length; i++) list.add(this.dataTx.types[i]);
  return list;
}

fan.dom.DataTransferPeer.prototype.getData = function(self, type)
{
  var val = this.dataTx.getData(type);
  if (val == "") val = this.data[type];
  return val;
}

fan.dom.DataTransferPeer.prototype.setData = function(self, type, val)
{
  // we keep a backup of data for WebKit workaround - see EventPeer.dataTransfer
  this.data[type] = val;
  return this.dataTx.setData(type, val);
}

fan.dom.DataTransferPeer.make = function(dataTx)
{
  var x = fan.dom.DataTransfer.make();
  x.peer.dataTx = dataTx;
  x.peer.data = {};
  return x;
}