//
// Copyright (c) 2019, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 19  Matthew Giannini  Creation
//

/**
 * ConcurrentMap
 */
fan.concurrent.ConcurrentMap = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

fan.concurrent.ConcurrentMap.make = function(capacity)
{
  var self = new fan.concurrent.ConcurrentMap();
  self.m_map = fan.sys.Map.make(fan.sys.Obj.$type, fan.sys.Obj.$type)
  return self;
}

fan.concurrent.ConcurrentMap.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.concurrent.ConcurrentMap.prototype.$typeof = function() { return fan.concurrent.ConcurrentMap.$type; }

//////////////////////////////////////////////////////////////////////////
// ConcurrentMap
//////////////////////////////////////////////////////////////////////////

fan.concurrent.ConcurrentMap.prototype.isEmpty = function() { return this.m_map.isEmpty(); }

fan.concurrent.ConcurrentMap.prototype.size = function() { return this.m_map.size(); }

fan.concurrent.ConcurrentMap.prototype.get = function(key) { return this.m_map.get(key); }

fan.concurrent.ConcurrentMap.prototype.set = function(key, val)
{
  this.m_map.set(key, this.$checkImmutable(val));
}

fan.concurrent.ConcurrentMap.prototype.add = function(key, val)
{
  if (this.containsKey(key)) throw fan.sys.Err("Key already mapped: " + key);
  this.m_map.add(key, this.$checkImmutable(val));
  console.log(this.m_map.toStr());
}

fan.concurrent.ConcurrentMap.prototype.getOrAdd = function(key, defVal)
{
  var val = this.m_map.get(key);
  if (val == null) { this.m_map.add(key, this.$checkImmutable(val = defVal)); }
  return val;
}

fan.concurrent.ConcurrentMap.prototype.setAll = function(m)
{
  if (m.isImmutable()) this.m_map.setAll(m);
  else
  {
    var vals = m.vals();
    for (i=0; i<vals.size(); ++i) { this.$checkImmutable(vals.get(i)); }
    this.m_map.setAll(m);
  }
  return this;
}

fan.concurrent.ConcurrentMap.prototype.remove = function(key) { return this.m_map.remove(key); }

fan.concurrent.ConcurrentMap.prototype.clear = function() { this.m_map.clear(); }

fan.concurrent.ConcurrentMap.prototype.each = function(f) { this.m_map.each(f); }

fan.concurrent.ConcurrentMap.prototype.eachWhile = function(f) { return this.m_map.eachWhile(f); }

fan.concurrent.ConcurrentMap.prototype.containsKey = function(key) { return this.m_map.containsKey(key); }

fan.concurrent.ConcurrentMap.prototype.keys = function(of)
{
  var array = [];
  this.m_map.$each(function(b) { array.push(b.key); });
  return fan.sys.List.make(of, array);
}

fan.concurrent.ConcurrentMap.prototype.vals = function(of)
{
  var array = [];
  this.m_map.$each(function(b) { array.push(b.val); });
  return fan.sys.List.make(of, array);
}

fan.concurrent.ConcurrentMap.prototype.$checkImmutable = function(val)
{
  if (fan.sys.ObjUtil.isImmutable(val)) return val;
  else throw fan.sys.NotImmutableErr.make();
}