//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jan 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Map.
 */
fan.sys.Map = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.make = function(k, v)
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

  var self = new fan.sys.Map();
  self.keyMap = {};
  self.valMap = {};
  self.m_readonly = false;
  self.m_immutable = false;
  self.m_type = mt;
  self.m_def = null;
  return self;
}

fan.sys.Map.prototype.$ctor = function()
{
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.$typeof = function()
{
  return this.m_type;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.isEmpty = function() { return this.size() == 0; }

fan.sys.Map.prototype.size = function()
{
  var sz = 0;
  for (var k in this.valMap) sz++;
  return sz;
}

fan.sys.Map.prototype.get = function(key, defVal)
{
  if (defVal === undefined) defVal = this.m_def;
  var k = this.hashKey(key);
  var val = this.valMap[k];
  if (val == null && defVal != null)
    return defVal;
  return val;
}

fan.sys.Map.prototype.containsKey = function(key)
{
  var hash = this.hashKey(key);
  for (var k in this.keyMap)
    if (k == hash)
      return true;
  return false;
}

fan.sys.Map.prototype.keys = function()
{
  var list = [];
  for (var k in this.keyMap) list.push(this.keyMap[k]);
  return fan.sys.List.make(this.m_type.k, list);
}

fan.sys.Map.prototype.vals = function()
{
  var list = [];
  for (var k in this.valMap) list.push(this.valMap[k]);
  return fan.sys.List.make(this.m_type.v, list);
}

fan.sys.Map.prototype.set = function(key, val)
{
  this.modify();
  if (key == null)
    throw fan.sys.NullErr.make("key is null");
  if (!fan.sys.ObjUtil.isImmutable(key))
    throw fan.sys.NotImmutableErr.make("key is not immutable: " + fan.sys.ObjUtil.$typeof(key));

  var k = this.hashKey(key);
  if (this.keyMap[k] == null) this.keyMap[k] = key;
  this.valMap[k] = val;
  return this;
}

fan.sys.Map.prototype.add = function(key, val)
{
  this.modify();
  if (key == null)
    throw fan.sys.NullErr.make("key is null");
  if (!fan.sys.ObjUtil.isImmutable(key))
    throw fan.sys.NotImmutableErr.make("key is not immutable: " + fan.sys.ObjUtil.$typeof(key));

  var k = this.hashKey(key);
  var old = this.valMap[k];
  if (old != null)
    throw fan.sys.ArgErr.make("Key already mapped: " + key);

  this.keyMap[k] = key;
  this.valMap[k] = val;
  return this;
}

fan.sys.Map.prototype.getOrAdd = function(key, valFunc)
{
  var k = this.hashKey(key);
  var val = this.valMap[k];
  if (val != null) return val;
  val = valFunc.call(key);
  this.add(key, val);
  return val;
}

fan.sys.Map.prototype.setAll = function(m)
{
  this.modify();
  var keys = m.keys();
  var len = keys.size();
  for (var i=0; i<len; i++)
  {
    var key = keys.get(i);
    this.set(key, m.get(key));
  }
  return this;
}

fan.sys.Map.prototype.addAll = function(m)
{
  this.modify();
  var keys = m.keys();
  var len = keys.size();
  for (var i=0; i<len; i++)
  {
    var key = keys.get(i);
    this.add(key, m.get(key));
  }
  return this;
}

fan.sys.Map.prototype.setList = function(list, f)
{
  this.modify();
  if (f === undefined) f = null;
  if (f == null)
  {
    for (var i=0; i<list.size(); ++i)
      this.set(list.get(i), list.get(i));
  }
  else if (f.m_params.size() == 1)
  {
    for (var i=0; i<list.size(); ++i)
      this.set(f.call(list.get(i)), list.get(i));
  }
  else
  {
    for (var i=0; i<list.size(); ++i)
      this.set(f.call(list.get(i), i), list.get(i));
  }
  return this;
}

fan.sys.Map.prototype.addList = function(list, f)
{
  this.modify();
  if (f === undefined) f = null;
  if (f == null)
  {
    for (var i=0; i<list.size(); ++i)
      this.add(list.get(i), list.get(i));
  }
  else if (f.m_params.size() == 1)
  {
    for (var i=0; i<list.size(); ++i)
      this.add(f.call(list.get(i)), list.get(i));
  }
  else
  {
    for (var i=0; i<list.size(); ++i)
      this.add(f.call(list.get(i), i), list.get(i));
  }
  return this;
}

fan.sys.Map.prototype.remove = function(key)
{
  this.modify();
  var k = this.hashKey(key);
  var v = this.valMap[k];
  delete this.keyMap[k];
  delete this.valMap[k];
  return v;
}

fan.sys.Map.prototype.dup = function()
{
  var dup = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  for (k in this.keyMap) dup.keyMap[k] = this.keyMap[k];
  for (k in this.valMap) dup.valMap[k] = this.valMap[k];
  dup.m_caseInsensitive = this.m_caseInsensitive;
  dup.m_ordered = this.m_ordered;
  dup.m_def = this.m_def;
  return dup;
}

fan.sys.Map.prototype.clear = function()
{
  this.modify();
  this.keyMap = {};
  this.valMap = {};
  return this;
}

fan.sys.Map.prototype.m_caseInsensitive = false;
fan.sys.Map.prototype.caseInsensitive = function() { return this.m_caseInsensitive; }
fan.sys.Map.prototype.caseInsensitive$ = function(val)
{
  this.modify();

  if (this.m_type.k != fan.sys.Str.$type)
    throw fan.sys.UnsupportedErr.make("Map not keyed by Str: " + this.m_type);

  if (this.size() != 0)
    throw fan.sys.UnsupportedErr.make("Map not empty");

  if (val && this.ordered())
    throw fan.sys.UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

  this.m_caseInsensitive = val;
}

fan.sys.Map.prototype.m_ordered = false;
fan.sys.Map.prototype.ordered = function() { return this.m_ordered; }
fan.sys.Map.prototype.ordered$ = function(val)
{
  this.modify();

  if (this.size() != 0)
    throw fan.sys.UnsupportedErr.make("Map not empty");

  if (val && this.caseInsensitive())
    throw fan.sys.UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

  this.m_ordered = val;
}

fan.sys.Map.prototype.def = function() { return this.m_def; }
fan.sys.Map.prototype.def$ = function(val)
{
  this.modify();
  if (val != null && !fan.sys.ObjUtil.isImmutable(val))
    throw fan.sys.NotImmutableErr.make("def must be immutable: " + fan.sys.ObjUtil.$typeof(val));
  this.m_def = val;
}

fan.sys.Map.prototype.equals = function(that)
{
  if (that != null)
  {
    if (!this.m_type.equals(that.m_type)) return false;
    var selfNum = 0;
    for (var k in this.valMap)
    {
      if (!fan.sys.ObjUtil.equals(this.valMap[k], that.valMap[k])) return false;
      selfNum++;
    }
    var thatNum = 0;
    for (var k in that.valMap) thatNum++;
    return selfNum == thatNum;
  }
  return false;
}

fan.sys.Map.prototype.hash = function()
{
  // TODO FIXIT
  return 0;
}

fan.sys.Map.prototype.toStr = function()
{
  var s = "";
  for (var k in this.valMap)
  {
    if (s.length > 0) s += ", ";
    s += this.keyMap[k] + ":" + this.valMap[k];
  }
  if (s.length == 0) return "[:]";
  return "[" + s + "]";
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.each = function(f)
{
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    f.call(val, key);
  }
}

fan.sys.Map.prototype.eachWhile = function(f)
{
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    var r = f.call(val, key);
    if (r != null) return r;
  }
  return null;
}

fan.sys.Map.prototype.find = function(f)
{
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (f.call(val, key))
      return val;
  }
  return null;
}

fan.sys.Map.prototype.findAll = function(f)
{
  var acc = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (f.call(val, key))
      acc.set(key, val);
  }
  return acc;
}

fan.sys.Map.prototype.exclude = function(f)
{
  var acc = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (!f.call(val, key))
      acc.set(key, val);
  }
  return acc;
}

fan.sys.Map.prototype.any = function(f)
{
  if (this.size() == 0) return false;
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (f.call(val, key))
      return true;
  }
  return false;
}

fan.sys.Map.prototype.all = function(f)
{
  if (this.size() == 0) return true;
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (!f.call(val, key))
      return false;
  }
  return true;
}

fan.sys.Map.prototype.reduce = function(reduction, f)
{
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    reduction = f.call(reduction, val, key)
  }
  return reduction;
}

fan.sys.Map.prototype.map = function(f)
{
  var r = f.returns();
  if (r == fan.sys.Void.$type) r = fan.sys.Obj.$type.toNullable();
  var acc = fan.sys.Map.make(this.m_type.k, r);
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    acc.set(key, f.call(val, key));
  }
  return acc;
}

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.join = function(sep, f)
{
  if (f === undefined) f = null;

  var size = this.size();
  if (size == 0) return '';
  var s = '';
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (s.length > 0) s += sep;
    if (f == null)
      s += key + ": " + val;
    else
      s += f.call(val, key);
  }
  return s;
}

fan.sys.Map.prototype.toCode = function()
{
  var size = this.size();
  var s = '';
  s += this.m_type.signature();
  s += '[';
  if (size == 0) s += ':';
  var first = true;
  for (var k in this.keyMap)
  {
    var key = this.keyMap[k];
    var val = this.valMap[k];
    if (first) first = false;
    else s += ', ';
    s += fan.sys.ObjUtil.trap(key, "toCode", null)
      + ':'
      + fan.sys.ObjUtil.trap(val, "toCode", null);
  }
  s += ']';
  return s;
}

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.isRW = function() { return !this.m_readonly; }

fan.sys.Map.prototype.isRO = function() { return this.m_readonly; }

fan.sys.Map.prototype.rw = function()
{
  if (!this.m_readonly) return this;

  var rw = this.dup();
  rw.m_caseInsensitive = this.m_caseInsensitive;
  rw.m_ordered = this.m_ordered;
  rw.m_readonly = false;
  rw.m_def = this.m_def;
  return rw;
}

fan.sys.Map.prototype.ro = function()
{
  if (this.m_readonly) return this;

  var ro = this.dup();
  ro.m_caseInsensitive = this.m_caseInsensitive;
  ro.m_ordered = this.m_ordered;
  ro.m_readonly = true;
  ro.m_def = this.m_def;
  return ro;
}

fan.sys.Map.prototype.isImmutable = function() { return this.m_immutable; }

fan.sys.Map.prototype.toImmutable = function()
{
  if (this.m_immutable) return this;

  var ro = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  for (k in this.keyMap) ro.keyMap[k] = this.keyMap[k];
  for (k in this.valMap) ro.valMap[k] = fan.sys.ObjUtil.toImmutable(this.valMap[k]);
  ro.m_caseInsensitive = this.m_caseInsensitive;
  ro.m_ordered = this.m_ordered;
  ro.m_readonly = true;
  ro.m_immutable = true;
  ro.m_def = this.m_def;
  return ro;
}

fan.sys.Map.prototype.modify = function()
{
  // if readonly then throw readonly exception
  if (this.m_readonly)
    throw fan.sys.ReadonlyErr.make("Map is readonly");
}

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.hashKey = function(key)
{
  // TODO: uniquly encode key object to string key
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  return '' + key;
}

fan.sys.Map.fromLiteral = function(keys, vals, k, v)
{
  var map = fan.sys.Map.make(k,v);
  for (var i=0; i<keys.length; i++)
    map.set(keys[i], vals[i]);
  return map;
}