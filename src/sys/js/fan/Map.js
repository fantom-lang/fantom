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
  if (k !== undefined && v === undefined)
  {
    mt = k;
  }
  else
  {
    if (k === undefined) k = fan.sys.Obj.$type;
    if (v === undefined) v = fan.sys.Obj.$type.toNullable();
    mt = new fan.sys.MapType(k, v);
  }
  this.keyMap = {};
  this.map = {};
  this.m_readonly = false;
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
  return this.$fanType;
}

fan.sys.Map.prototype.toStr = function()
{
  var s = "";
  for (var k in this.map)
  {
    if (s.length > 0) s += ", ";
    s += this.keyMap[k] + ":" + this.map[k];
  }
  if (s.length == 0) return "[:]";
  return "[" + s + "]";
}

fan.sys.Map.prototype.caseInsensitive = function() { return this.m_caseInsensitive; }
fan.sys.Map.prototype.caseInsensitive$ = function(v) { this.m_caseInsensitive = v; }
fan.sys.Map.prototype.m_caseInsensitive = false;

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
  return fan.sys.List.make(this.$fanType.v, list);
}

fan.sys.Map.prototype.get = function(key, defVal)
{
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  var val = this.map[key];
  if (val == null && defVal != null)
    return defVal;
  return val;
}

fan.sys.Map.prototype.containsKey = function(key)
{
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  for (var k in this.map)
    if (fan.sys.ObjUtil.equals(k, key))
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
  var orig = key;
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  this.keyMap[key] = orig;
  this.map[key] = val;
  return this;
}


fan.sys.Map.prototype.setAll = function(m)
{
  //modify();
  var keys = m.keys();
  var len = keys.length;
  for (var i=0; i<len; i++)
  {
    var key = keys[i];
    this.set(key, m.get(key));
  }
  return this;
}

fan.sys.Map.prototype.remove = function(key)
{
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  var v = this.map[key];
  delete this.keyMap[key];
  delete this.map[key];
  return v;
}

fan.sys.Map.prototype.isEmpty = function() { return this.size() == 0; }
fan.sys.Map.prototype.size = function()
{
  var sz = 0;
  for (var k in this.map) sz++;
  return sz;
}

fan.sys.Map.prototype.dup = function()
{
  var dup = new fan.sys.Map(this.$fanType.k, this.$fanType.v);
  for (prop in this.keyMap) dup.keyMap[prop] = this.keyMap[prop];
  for (prop in this.map) dup.map[prop] = this.map[prop];
  return dup;
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
  this.m_readonly = true;
  return this;
}

fan.sys.Map.prototype.ro = function()
{
  // TODO
  this.m_readonly = true;
  return this;
}

fan.sys.Map.prototype.isRO = function() { return this.m_readonly; }
fan.sys.Map.prototype.isRW = function() { return !this.m_readonly; }

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