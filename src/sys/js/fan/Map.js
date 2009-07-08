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
var sys_Map = sys_Obj.$extend(sys_Obj);

sys_Map.prototype.$ctor = function(k, v)
{
  var mt = null;
  if (k != undefined && v == undefined)
  {
    mt = k;
  }
  else
  {
    if (k == undefined) k = sys_Type.find("sys::Obj")
    if (v == undefined) v = sys_Type.find("sys::Obj")
    mt = new sys_MapType(k, v);
  }
  this.map = {};
  this.$fanType = mt;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_Map.prototype.equals = function(that)
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

sys_Map.prototype.hash = function()
{
  return 0;
}

sys_Map.prototype.type = function()
{
  return sys_Type.find("sys::Map");
}

sys_Map.prototype.toStr = function()
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

sys_Map.prototype.keys = function()
{
  var list = [];
  for (var k in this.map) list.push(k);
  return list;
}

sys_Map.prototype.values = function()
{
  var list = [];
  for (var k in this.map) list.push(this.map[k]);
  return list;
}

sys_Map.prototype.get = function(key, defVal)
{
  var val = this.map[key];
  if (val == null && defVal != null)
    return defVal;
  return val;
}

sys_Map.prototype.containsKey = function(key)
{
  for (var k in this.map)
    if (sys_Obj.equals(k, key))
      return true;
  return false;
}

sys_Map.prototype.add = function(key, val)
{
  if (key == null)
    throw sys_NullErr.make("key is null");
  //if (!isImmutable(key))
  //  throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
  if (this.map.hasOwnProperty(key))
    throw sys_ArgErr.make("Key already mapped: " + key);
  this.map[key] = val;
  return this;
}

sys_Map.prototype.set = function(key, val)
{
  this.map[key] = val;
  return this;
}

sys_Map.prototype.isEmpty = function() { return this.size() == 0; }
sys_Map.prototype.size = function()
{
  var sz = 0;
  for (var k in this.map) sz++;
  return sz;
}

sys_Map.prototype.ordered$get = function() { return this.ordered; }
sys_Map.prototype.ordered$set = function(val)
{
  if (this.size() != 0)
    throw sys_UnsupportedErr.make("Map not empty");

  this.ordered = val;
}
sys_Map.prototype.ordered = false;

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

sys_Map.prototype.each = function(func)
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

sys_Map.prototype.toImmutable = function()
{
  // TODO
  return this;
}

sys_Map.prototype.ro = function()
{
  // TODO
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Map.fromLiteral = function(keys, vals, k, v)
{
  var map = new sys_Map(k,v);
  for (var i=0; i<keys.length; i++)
    map.set(keys[i], vals[i]);
  return map;
}