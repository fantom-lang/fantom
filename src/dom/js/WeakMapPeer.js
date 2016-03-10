//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Mar 2016  Andy Frank  Creation
//

fan.dom.WeakMapPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.WeakMapPeer.prototype.$ctor = function(self) { this.map = new WeakMap(); }
fan.dom.WeakMapPeer.prototype.has = function(self, key) { return this.map.has(key); }
fan.dom.WeakMapPeer.prototype.get = function(self, key) { return this.map.get(key); }
fan.dom.WeakMapPeer.prototype.set = function(self, key, val) { this.map.set(key, val); return self; }
fan.dom.WeakMapPeer.prototype.delete = function(self, key) { return this.map.delete(key); }
