//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 10  Andy Frank  Created
//

fan.dom.StoragePeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.dom.StoragePeer.prototype.$ctor = function(self) {}
fan.dom.StoragePeer.prototype.$instance = null;

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.dom.StoragePeer.prototype.size = function(self, key)
{
  return this.$instance.length;
}

fan.dom.StoragePeer.prototype.key = function(self, index)
{
  return this.$instance.key(index);
}

fan.dom.StoragePeer.prototype.get = function(self, key)
{
  return this.$instance.getItem(key);
}

fan.dom.StoragePeer.prototype.set = function(self, key, val)
{
  this.$instance.setItem(key, val);
}

fan.dom.StoragePeer.prototype.remove = function(self, key)
{
  this.$instance.removeItem(key);
}

fan.dom.StoragePeer.prototype.clear = function(self)
{
  this.$instance.clear();
}

