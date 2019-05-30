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
  if (mt.k.isNullable()) throw fan.sys.ArgErr.make("map key type cannot be nullable: " + mt.k.toStr());
  var self = new fan.sys.Map();
  self.m_vals = [];
  self.m_keys = null;  // only used for ordered
  self.m_size = 0;
  self.m_readonly = false;
  self.m_immutable = false;
  self.m_type = mt;
  self.m_def = null;
  return self;
}

fan.sys.Map.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.$typeof = function() { return this.m_type; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.isEmpty = function() { return this.m_size == 0; }

fan.sys.Map.prototype.size = function() { return this.m_size; }

fan.sys.Map.prototype.get = function(key, defVal)
{
  var val = this.$get(key);
  if (val === undefined)
  {
    val = defVal;
    if (val === undefined) val = this.m_def;
  }
  return val;
}

fan.sys.Map.prototype.getChecked = function(key, checked)
{
  if (checked === undefined) checked = true;
  var val = this.$get(key);
  if (val === undefined)
  {
    if (checked) throw fan.sys.UnknownKeyErr.make("" + key);
    return null;
  }
  return val;
}

fan.sys.Map.prototype.getOrThrow = function(key)
{
  var val = this.$get(key);
  if (val === undefined)
    throw fan.sys.UnknownKeyErr.make("" + key);
  return val;
}

fan.sys.Map.prototype.containsKey = function(key)
{
  return this.$get(key) !== undefined;
}

fan.sys.Map.prototype.keys = function()
{
  var array = [];
  this.$each(function(b) { array.push(b.key); });
  return fan.sys.List.make(this.m_type.k, array);
}

fan.sys.Map.prototype.vals = function()
{
  var array = [];
  this.$each(function(b) { array.push(b.val); });
  return fan.sys.List.make(this.m_type.v, array);
}

fan.sys.Map.prototype.set = function(key, val)
{
  this.modify();
  if (key == null)
    throw fan.sys.NullErr.make("key is null");
  if (!fan.sys.ObjUtil.isImmutable(key))
    throw fan.sys.NotImmutableErr.make("key is not immutable: " + fan.sys.ObjUtil.$typeof(key));
  this.$set(key, val);
  return this;
}

fan.sys.Map.prototype.add = function(key, val)
{
  this.modify();
  if (key == null)
    throw fan.sys.NullErr.make("key is null");
  if (!fan.sys.ObjUtil.isImmutable(key))
    throw fan.sys.NotImmutableErr.make("key is not immutable: " + fan.sys.ObjUtil.$typeof(key));
  this.$set(key, val, true);
  return this;
}

fan.sys.Map.prototype.addIfNotNull = function(key, val)
{
  if (val == null) return this;
  return this.add(key, val);
}

fan.sys.Map.prototype.getOrAdd = function(key, valFunc)
{
  var val = this.$get(key);
  if (val !== undefined) return val;
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
  return this.$remove(key);
}

fan.sys.Map.prototype.dup = function()
{
  var dup = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  if (this.m_ordered) dup.ordered$(true);
  if (this.m_caseInsensitive) dup.caseInsensitive$(true);
  dup.m_def = this.m_def;
  this.$each(function(b) { dup.set(b.key, b.val); });
  return dup;
}

fan.sys.Map.prototype.clear = function()
{
  this.modify();
  if (this.m_ordered) this.m_keys = [];
  this.m_vals = [];
  this.m_size = 0;
  return this;
}

fan.sys.Map.prototype.m_caseInsensitive = false;
fan.sys.Map.prototype.caseInsensitive = function() { return this.m_caseInsensitive; }
fan.sys.Map.prototype.caseInsensitive$ = function(val)
{
  this.modify();

  if (this.m_type.k != fan.sys.Str.$type)
    throw fan.sys.UnsupportedErr.make("Map not keyed by Str: " + this.m_type);

  if (this.m_size != 0)
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

  if (this.m_size != 0)
    throw fan.sys.UnsupportedErr.make("Map not empty");

  if (val && this.caseInsensitive())
    throw fan.sys.UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

  this.m_ordered = val;
  this.m_keys = [];
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
    if (this.m_size != that.m_size) return false;
    var eq = true;
    this.$each(function(b)
    {
      eq = fan.sys.ObjUtil.equals(b.val, that.get(b.key));
      return eq;
    });
    return eq;
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
  if (this.m_size == 0) return "[:]";
  var s = "";
  this.$each(function(b)
  {
    if (s.length > 0) s += ", ";
    s += b.key + ":" + b.val;
  });
  return "[" + s + "]";
}

fan.sys.Map.prototype.$literalEncode = function(out)
{
  // route back to obj encoder
  out.writeMap(this);
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.each = function(f)
{
  this.$each(function(b) { f.call(b.val, b.key); });
}

fan.sys.Map.prototype.eachWhile = function(f)
{
  var result = null;
  this.$each(function(b)
  {
    var r = f.call(b.val, b.key);
    if (r != null) { result=r; return false; }
  });
  return result;
}

fan.sys.Map.prototype.find = function(f)
{
  var result = null;
  this.$each(function(b)
  {
    if (f.call(b.val, b.key))
    {
      result = b.val;
      return false;
    }
  });
  return result;
}

fan.sys.Map.prototype.findAll = function(f)
{
  var acc = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  if (this.m_ordered) acc.ordered$(true);
  if (this.m_caseInsensitive) acc.caseInsensitive$(true);
  this.$each(function(b)
  {
    if (f.call(b.val, b.key))
      acc.set(b.key, b.val);
  });
  return acc;
}

fan.sys.Map.prototype.exclude = function(f)
{
  var acc = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  if (this.m_ordered) acc.ordered$(true);
  if (this.m_caseInsensitive) acc.caseInsensitive$(true);
  this.$each(function(b)
  {
    if (!f.call(b.val, b.key))
      acc.set(b.key, b.val);
  });
  return acc;
}

fan.sys.Map.prototype.any = function(f)
{
  if (this.m_size == 0) return false;
  var any = false;
  this.$each(function(b)
  {
    if (f.call(b.val, b.key))
    {
      any = true;
      return false;
    }
  });
  return any;
}

fan.sys.Map.prototype.all = function(f)
{
  if (this.m_size == 0) return true;
  var all = true;
  this.$each(function(b)
  {
    if (!f.call(b.val, b.key))
    {
      all = false
      return false;
    }
  });
  return all;
}

fan.sys.Map.prototype.reduce = function(reduction, f)
{
  this.$each(function(b) { reduction = f.call(reduction, b.val, b.key); });
  return reduction;
}

fan.sys.Map.prototype.map = function(f)
{
  var r = f.returns();
  if (r == fan.sys.Void.$type) r = fan.sys.Obj.$type.toNullable();
  var acc = fan.sys.Map.make(this.m_type.k, r);
  if (this.m_ordered) acc.ordered$(true);
  if (this.m_caseInsensitive) acc.caseInsensitive$(true);
  this.$each(function(b) { acc.add(b.key, f.call(b.val, b.key)); });
  return acc;
}

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.prototype.join = function(sep, f)
{
  if (f === undefined) f = null;
  if (this.m_size == 0) return "";
  var s = "";
  this.$each(function(b)
  {
    if (s.length > 0) s += sep;
    if (f == null)
      s += b.key + ": " + b.val;
    else
      s += f.call(b.val, b.key);
  });
  return s;
}

fan.sys.Map.prototype.toCode = function()
{
  var size = this.m_size;
  var s = '';
  s += this.m_type.signature();
  s += '[';
  if (size == 0) s += ':';
  var first = true;
  this.$each(function(b)
  {
    if (first) first = false;
    else s += ', ';
    s += fan.sys.ObjUtil.trap(b.key, "toCode", null)
      + ':'
      + fan.sys.ObjUtil.trap(b.val, "toCode", null);
  });
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
  rw.m_readonly = false;
  return rw;
}

fan.sys.Map.prototype.ro = function()
{
  if (this.m_readonly) return this;
  var ro = this.dup();
  ro.m_readonly = true;
  return ro;
}

fan.sys.Map.prototype.isImmutable = function() { return this.m_immutable; }

fan.sys.Map.prototype.toImmutable = function()
{
  if (this.m_immutable) return this;
  var ro = fan.sys.Map.make(this.m_type.k, this.m_type.v);
  if (this.m_ordered) ro.ordered$(true);
  if (this.m_caseInsensitive) ro.caseInsensitive$(true);
  this.$each(function(b)
  {
    ro.set(b.key, fan.sys.ObjUtil.toImmutable(b.val));
  });
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
// Internal
//////////////////////////////////////////////////////////////////////////

fan.sys.Map.fromLiteral = function(keys, vals, k, v)
{
  var map = fan.sys.Map.make(k,v);
  for (var i=0; i<keys.length; i++)
    map.set(keys[i], vals[i]);
  return map;
}

fan.sys.Map.prototype.hashKey = function(key)
{
  if (this.m_caseInsensitive) key = fan.sys.Str.lower(key);
  return fan.sys.ObjUtil.hash(key);
}

fan.sys.Map.prototype.keysEqual = function(a, b)
{
  return (this.m_caseInsensitive)
    ? fan.sys.Str.equalsIgnoreCase(a, b)
    : fan.sys.ObjUtil.equals(a, b);
}

fan.sys.Map.prototype.$get = function(key, val)
{
  var b = this.m_vals[this.hashKey(key)];
  while (b !== undefined)
  {
    if (this.keysEqual(b.key, key)) return b.val;
    b = b.next;
  }
  return undefined;
}

fan.sys.Map.prototype.$set = function(key, val, add)
{
  var n = { key:key, val:val };
  var h = this.hashKey(key);
  var b = this.m_vals[h];
  if (b === undefined)
  {
    if (this.m_ordered)
    {
      n.ki = this.m_keys.length;
      this.m_keys.push(key);
    }
    this.m_vals[h] = n;
    this.m_size++;
    return
  }
  while (true)
  {
    if (this.keysEqual(b.key, key))
    {
      if (add) throw fan.sys.ArgErr.make("Key already mapped: " + key);
      b.val = val;
      return;
    }
    if (b.next === undefined)
    {
      if (this.m_ordered)
      {
        n.ki = this.m_keys.length;
        this.m_keys.push(key);
      }
      b.next = n;
      this.m_size++;
      return;
    }
    b = b.next;
  }
}

fan.sys.Map.prototype.$remove = function(key)
{
  var h = this.hashKey(key);
  var b = this.m_vals[h];
  if (b === undefined) return null;
  if (b.next === undefined)
  {
    if (this.m_ordered) this.m_keys[b.ki] = undefined;
    this.m_vals[h] = undefined;
    this.m_size--;
    var v = b.val;
    delete b;
    return v;
  }
  var prev = undefined;
  while (b !== undefined)
  {
    if (this.keysEqual(b.key, key))
    {
      if (prev !== undefined && b.next !== undefined) prev.next = b.next;
      else if (prev === undefined) this.m_vals[h] = b.next;
      else if (b.next === undefined) prev.next = undefined;
      if (this.m_ordered) this.m_keys[b.ki] = undefined;
      this.m_size--;
      var v = b.val
      delete b;
      return v;
    }
    prev = b;
    b = b.next;
  }
  return null;
}

fan.sys.Map.prototype.$each = function(func)
{
  if (this.m_ordered)
  {
    for (var i=0; i<this.m_keys.length; i++)
    {
      var k = this.m_keys[i];
      if (k === undefined) continue;
      var v = this.$get(k);
      if (func({ key:k, ki:i, val:v }) === false) return;
    }
  }
  else
  {
    for (var h in this.m_vals)
    {
      var b = this.m_vals[h];
      while (b !== undefined)
      {
        if (func(b) === false) return;
        b = b.next;
      }
    }
  }
}