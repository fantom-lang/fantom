//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jan 09  Andy Frank  Creation
//

/**
 * Map - TODO
 */
var sys_Map = sys_Obj.extend(
{
  $ctor: function() { this.map = {}; },
  type: function()  { return sys_Type.find("sys::Map"); },

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals: function(that)
  {
    if (that != null)
    {
      if (this.keyType != that.keyType) return false;
      if (this.valType != that.valType) return false;
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
  },

  hash: function() { return 0; },

  toStr: function()
  {
    var s = "";
    for (var k in this.map)
    {
      if (s.length > 0) s += ", ";
      s += k + ":" + this.map[k];
    }
    if (s.length == 0) return "[:]";
    return "[" + s + "]";
  },

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  keys: function()
  {
    var list = [];
    for (var k in this.map) list.push(k);
    return list;
  },

  values: function()
  {
    var list = [];
    for (var k in this.map) list.push(this.map[k]);
    return list;
  },

  get: function(key, defVal)
  {
    var val = this.map[key];
    if (val == null && defVal != null)
      return defVal;
    return val;
  },

  add: function(key, val)
  {
    if (this.map.hasOwnProperty(key))
    {
      var old = this.map[key];
      if (old != null)
        throw new sys_ArgErr("Key already mapped: " + key);
    }
    this.map[key] = val;
    return this;
  },

  set: function(key, val)
  {
    this.map[key] = val;
    return this;
  },

  isEmpty: function() { return this.size() == 0; },
  size: function()
  {
    var sz = 0;
    for (var k in this.map) sz++;
    return sz;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  keyType: "sys::Obj",
  valType: "sys::Obj",

  map: null

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Map.fromLiteral = function(keys, vals, ktype, vtype)
{
  var map = new sys_Map();
  if (ktype != null) map.keyType = ktype;
  if (vtype != null) map.valType = vtype;
  for (var i=0; i<keys.length; i++)
    map.set(keys[i], vals[i]);
  return map;
}