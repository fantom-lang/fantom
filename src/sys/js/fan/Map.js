//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jan 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Map - TODO
 */
fan.sys.Map = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Map.prototype.$ctor = function(k, v)
{
  var mt = null;
  if (k != undefined && v == undefined)
  {
    mt = k;
  }
  else
  {
    if (k == undefined) k = fan.sys.Type.find("sys::Obj")
    if (v == undefined) v = fan.sys.Type.find("sys::Obj")
    mt = new fan.sys.MapType(k, v);
  }
  this.keyMap = {};
  this.map = {};
  this.$fanType = mt;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.equals = function(that)
{
  if (that != null)
  {
    if (!this.$fanType.equals(that.$fanType)) return false;
    var selfNum = 0;
    for (var k in this.map)
    {
      if (this.map[k] != that.map[k]) return false;
      selfNum++;
    }
    var thatNum = 0;
    for (var k in that.map) thatNum++;
    return selfNum == thatNum;
  }
  return false;
}

fan.sys.Map.prototype.hash = function()
{
  return 0;
}

fan.sys.Map.prototype.type = function()
{
  return fan.sys.Type.find("sys::Map");
}

fan.sys.Map.prototype.toStr = function()
{
  var s = "";
  for (var k in this.map)
  {
    if (s.length > 0) s += ", ";
    s += k + ":" + this.map[k];
  }
  if (s.length == 0) return "[:]";
  return "[" + s + "]";
}

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.keys = function()
{
  var list = [];
  for (var k in this.keyMap) list.push(this.keyMap[k]);
  return fan.sys.List.make(this.$fanType.k, list);
}

fan.sys.Map.prototype.values = function()
{
  var list = [];
  for (var k in this.map) list.push(this.map[k]);
  return list;
}

fan.sys.Map.prototype.get = function(key, defVal)
{
  var val = this.map[key];
  if (val == null && defVal != null)
    return defVal;
  return val;
}

fan.sys.Map.prototype.containsKey = function(key)
{
  for (var k in this.map)
    if (fan.sys.Obj.equals(k, key))
      return true;
  return false;
}

fan.sys.Map.prototype.add = function(key, val)
{
  if (key == null)
    throw fan.sys.NullErr.make("key is null");
  //if (!isImmutable(key))
  //  throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
  if (this.map.hasOwnProperty(key))
    throw fan.sys.ArgErr.make("Key already mapped: " + key);
  this.set(key, val);
  return this;
}

fan.sys.Map.prototype.set = function(key, val)
{
  this.keyMap[key] = key;
  this.map[key] = val;
  return this;
}

fan.sys.Map.prototype.isEmpty = function() { return this.size() == 0; }
fan.sys.Map.prototype.size = function()
{
  var sz = 0;
  for (var k in this.map) sz++;
  return sz;
}

fan.sys.Map.prototype.clear = function()
{
  this.keyMap = {};
  this.map = {};
  return this;
}

fan.sys.Map.prototype.ordered = function() { return this.m_ordered; }
fan.sys.Map.prototype.ordered$ = function(val)
{
  if (this.size() != 0)
    throw fan.sys.UnsupportedErr.make("Map not empty");

  this.ordered = val;
}
fan.sys.Map.prototype.m_ordered = false;

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.each = function(func)
{
  for (var k in this.map)
  {
    var v = this.map[k];
    func(v, k);
  }
}

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.toImmutable = function()
{
  // TODO
  return this;
}

fan.sys.Map.prototype.ro = function()
{
  // TODO
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.fromLiteral = function(keys, vals, k, v)
{
  var map = new fan.sys.Map(k,v);
  for (var i=0; i<keys.length; i++)
    map.set(keys[i], vals[i]);
  return map;
}