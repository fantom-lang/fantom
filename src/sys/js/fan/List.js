//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   3 Dec 09   Andy Frank  Wrap Array object
//

/**
 * List
 */
fan.sys.List = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

fan.sys.List.make = function(of, values)
{
  if (values === undefined) values = [];

  var self = new fan.sys.List();
  self.m_of = of;
  self.m_size = values.length;
  self.m_values = values;
  self.m_readonly = false;
  self.m_immutable = false;
  return self;
}

fan.sys.List.prototype.$ctor = function()
{
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.$typeof = function() { return this.m_of.toListOf(); }
fan.sys.List.prototype.of = function() { return this.m_of; }

fan.sys.List.prototype.isEmpty = function() { return this.m_size == 0; }

fan.sys.List.prototype.size = function() { return this.m_size; }
fan.sys.List.prototype.size$ = function(val)
{
  this.modify();
  var oldSize = this.m_size;
  var newSize = val;
  for (var i=0; this.m_size+i<newSize; i++)
    this.m_values.push(null);
  this.m_size = newSize;
}

fan.sys.List.prototype.capacity = function() { return this.m_values.length; }
fan.sys.List.prototype.capacity$ = function(val)
{
  if (val < this.m_size) throw fan.sys.ArgErr.make("capacity < size");
  // noop
}

fan.sys.List.prototype.get = function(index)
{
  if (index < 0) index = this.m_size + index;
  if (index >= this.m_size || index < 0) throw fan.sys.IndexErr.make(index);
  return this.m_values[index];
}

fan.sys.List.prototype.getSafe = function(index, def)
{
  if (def === undefined) def = null;
  if (index < 0) index = this.m_size + index;
  if (index >= this.m_size || index < 0) return def;
  return this.m_values[index];
}

fan.sys.List.prototype.getRange = function(range)
{
  var s = range.$start(this.m_size);
  var e = range.$end(this.m_size);
  if (e+1 < s || s < 0) throw fan.sys.IndexErr.make(range);
  return fan.sys.List.make(this.m_of, this.m_values.slice(s, e+1));
}

fan.sys.List.prototype.contains = function(value)
{
  return this.index(value) != null;
}

fan.sys.List.prototype.containsAll = function(list)
{
  for (var i=0; i<list.size(); ++i)
    if (this.index(list.get(i)) == null)
      return false;
  return true;
}

fan.sys.List.prototype.containsAny = function(list)
{
  for (var i=0; i<list.size(); ++i)
    if (this.index(list.get(i)) != null)
      return true;
  return false;
}

fan.sys.List.prototype.index = function(value, off)
{
  if (off === undefined) off = 0;

  var size = this.m_size;
  var values = this.m_values;
  if (size == 0) return null;
  var start = off;
  if (start < 0) start = size + start;
  if (start >= size || start < 0) throw fan.sys.IndexErr.make(off);

  if (value == null)
  {
    for (var i=start; i<size; ++i)
      if (values[i] == null)
        return i;
  }
  else
  {
    for (var i=start; i<size; ++i)
    {
      var obj = values[i];
      if (obj != null && fan.sys.ObjUtil.equals(obj, value))
        return i;
    }
  }
  return null;
}

fan.sys.List.prototype.indexSame = function(value, off)
{
  if (off === undefined) off = 0;

  var size = this.m_size;
  var values = this.m_values;
  if (size == 0) return null;
  var start = off;
  if (start < 0) start = size + start;
  if (start >= size || start < 0) throw fan.sys.IndexErr.make(off);

  for (var i=start; i<size; i++)
    if (value === values[i])
      return i;
  return null;
}

fan.sys.List.prototype.first = function()
{
  if (this.m_size == 0) return null;
  return this.m_values[0];
}

fan.sys.List.prototype.last = function()
{
  if (this.m_size == 0) return null;
  return this.m_values[this.m_size-1];
}

fan.sys.List.prototype.dup = function()
{
  return fan.sys.List.make(this.m_of, this.m_values.slice(0));
}

fan.sys.List.prototype.hash = function()
{
  var hash = 33;
  var size = this.m_size;
  var vals = this.m_values;
  for (var i=0; i<size; ++i)
  {
    var obj = vals[i];
    if (obj != null) hash ^= fan.sys.ObjUtil.hash(obj);
  }
  return hash;
}

fan.sys.List.prototype.equals = function(that)
{
  if (that instanceof fan.sys.List)
  {
    if (!this.m_of.equals(that.m_of)) return false;
    if (this.m_size != that.m_size) return false;
    for (var i=0; i<this.m_size; ++i)
      if (!fan.sys.ObjUtil.equals(this.m_values[i], that.m_values[i]))
        return false;
    return true;
  }
  return false;
}

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.set = function(index, value)
{
  this.modify();
  //try
  //{
    if (index < 0) index = this.m_size + index;
    if (index >= this.m_size || index < 0) throw fan.sys.IndexErr.make(index);
    this.m_values[index] = value;
    return this;
  //}
  //catch (ArrayIndexOutOfBoundsException e)
  //{
  //  throw IndexErr.make(index).val;
  //}
  //catch (ArrayStoreException e)
  //{
  //  throw CastErr.make("Setting '" + FanObj.type(value) + "' into '" + of + "[]'").val;
  //}
}

fan.sys.List.prototype.add = function(value)
{
  // modify in insert$
  return this.insert$(this.m_size, value);
}

fan.sys.List.prototype.addAll = function(list)
{
  // modify in insertAll$
  return this.insertAll$(this.m_size, list);
}

fan.sys.List.prototype.insert = function(index, value)
{
  // modify in insert$
  if (index < 0) index = this.m_size + index;
  if (index > this.m_size || index < 0) throw fan.sys.IndexErr.make(index);
  return this.insert$(index, value);
}

fan.sys.List.prototype.insert$ = function(i, value)
{
  //try
  //{
    this.modify();
    this.m_values.splice(i, 0, value);
    this.m_size++;
    return this;
  //}
  //catch (ArrayStoreException e)
  //{
  //  throw CastErr.make("Adding '" + FanObj.type(value) + "' into '" + of + "[]'").val;
  //}
}

fan.sys.List.prototype.insertAll = function(index, list)
{
  // modify in insertAll$
  if (index < 0) index = this.m_size + index;
  if (index > this.m_size || index < 0) throw fan.sys.IndexErr.make(index);
  return this.insertAll$(index, list);
}

fan.sys.List.prototype.insertAll$ = function(i, list)
{
  // TODO: worth it to optimze small lists?
  // splice(i, 0, list[0], list[1], list[2])
  this.modify();
  if (list.m_size == 0) return this;
  var vals = list.m_values;
  if (this.m_values === vals) vals = vals.slice(0);
  for (var j=0; j<list.m_size; j++)
    this.m_values.splice(i+j, 0, vals[j]);
  this.m_size += list.m_size;
  return this;
}

fan.sys.List.prototype.remove = function(value)
{
  // modify in removeAt
  var index = this.index(value);
  if (index == null) return null;
  return this.removeAt(index);
}

fan.sys.List.prototype.removeSame = function(value)
{
  // modify in removeAt
  var index = this.indexSame(value);
  if (index == null) return null;
  return this.removeAt(index);
}

fan.sys.List.prototype.removeAt = function(index)
{
  this.modify();
  if (index < 0) index = this.m_size + index;
  if (index >= this.m_size || index < 0) throw fan.sys.IndexErr.make(index);
  var old = this.m_values.splice(index, 1);
  this.m_size--;
  return old[0];
}

fan.sys.List.prototype.removeRange = function(r)
{
  this.modify();
  var s = r.$start(this.m_size);
  var e = r.$end(this.m_size);
  var n = e - s + 1;
  if (n < 0) throw fan.sys.IndexErr.make(r);
  this.m_values.splice(s, n);
  this.m_size -= n;
  return this;
}

fan.sys.List.prototype.trim = function()
{
  this.modify();
  return this;
}

fan.sys.List.prototype.clear = function()
{
  this.modify();
  this.m_values.splice(0, this.m_size);
  this.m_size = 0;
  return this;
}

fan.sys.List.prototype.fill = function(value, times)
{
  this.modify();
  for (var i=0; i<times; i++) this.add(value);
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.peek = function()
{
  if (this.m_size == 0) return null;
  return this.m_values[this.m_size-1];
}

fan.sys.List.prototype.pop = function()
{
  // modify in removeAt()
  if (this.m_size == 0) return null;
  return this.removeAt(-1);
}

fan.sys.List.prototype.push = function(obj)
{
  // modify in add()
  return this.add(obj);
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.each = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; i++)
      f.call(this.m_values[i])
  }
  else
  {
    for (var i=0; i<this.m_size; i++)
      f.call(this.m_values[i], i)
  }
}

fan.sys.List.prototype.eachr = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=this.m_size-1; i>=0; i--)
      f.call(this.m_values[i])
  }
  else
  {
    for (var i=this.m_size-1; i>=0; i--)
      f.call(this.m_values[i], i)
  }
}

fan.sys.List.prototype.eachRange = function(r, f)
{
  var s = r.$start(this.m_size);
  var e = r.$end(this.m_size);
  var n = e - s + 1;
  if (n < 0) throw fan.sys.IndexErr.make(r);

  if (f.m_params.size() == 1)
  {
    for (var i=s; i<=e; ++i)
      f.call(this.m_values[i]);
  }
  else
  {
    for (var i=s; i<=e; ++i)
      f.call(this.m_values[i], i);
  }
}

fan.sys.List.prototype.eachWhile = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
    {
      var r = f.call(this.m_values[i]);
      if (r != null) return r;
    }
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
    {
      var r = f.call(this.m_values[i], i);
      if (r != null) return r;
    }
  }
  return null;
}

fan.sys.List.prototype.eachrWhile = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=this.m_size-1; i>=0; i--)
    {
      var r = f.call(this.m_values[i]);
      if (r != null) return r;
    }
  }
  else
  {
    for (var i=this.m_size-1; i>=0; i--)
    {
      var r = f.call(this.m_values[i], i);
      if (r != null) return r;
    }
  }
  return null;
}

fan.sys.List.prototype.find = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i]) == true)
        return this.m_values[i];
  }
  else
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i], i) == true)
        return this.m_values[i];
  }
  return null;
}

fan.sys.List.prototype.findIndex = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i]) == true)
        return i;
  }
  else
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i], i) == true)
        return i;
  }
  return null;
}

fan.sys.List.prototype.findAll = function(f)
{
  var acc = fan.sys.List.make(this.m_of);
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i]) == true)
        acc.add(this.m_values[i]);
  }
  else
  {
    for (var i=0; i<this.m_size; i++)
      if (f.call(this.m_values[i], i) == true)
        acc.add(this.m_values[i]);
  }
  return acc;
}

fan.sys.List.prototype.findType = function(t)
{
  var acc = fan.sys.List.make(t);
  for (var i=0; i<this.m_size; ++i)
  {
    var item = this.m_values[i];
    if (item != null && fan.sys.ObjUtil.$typeof(item).is(t))
      acc.add(item);
  }
  return acc;
}

fan.sys.List.prototype.exclude = function(f)
{
  var acc = fan.sys.List.make(this.m_of);
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i]) != true)
        acc.add(this.m_values[i]);
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i], i) != true)
        acc.add(this.m_values[i]);
  }
  return acc;
}

fan.sys.List.prototype.any = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i]) == true)
        return true;
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i], i) == true)
        return true;
  }
  return false;
}

fan.sys.List.prototype.all = function(f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i]) != true)
        return false;
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
      if (f.call(this.m_values[i], i) != true)
        return false;
  }
  return true;
}

fan.sys.List.prototype.reduce = function(reduction, f)
{
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
      reduction = f.call(reduction, this.m_values[i]);
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
      reduction = f.call(reduction, this.m_values[i], i);
  }
  return reduction;
}

fan.sys.List.prototype.map = function(f)
{
  var r = f.returns();
  if (r == fan.sys.Void.$type) r = fan.sys.Obj.$type.toNullable();
  var acc = fan.sys.List.make(r);
  if (f.m_params.size() == 1)
  {
    for (var i=0; i<this.m_size; ++i)
      acc.add(f.call(this.m_values[i]));
  }
  else
  {
    for (var i=0; i<this.m_size; ++i)
      acc.add(f.call(this.m_values[i], i));
  }
  return acc;
}

fan.sys.List.prototype.max = function(f)
{
  if (f === undefined) f = null;
  if (this.m_size == 0) return null;
  var max = this.m_values[0];
  for (var i=1; i<this.m_size; ++i)
  {
    var s = this.m_values[i];
    if (f == null)
      max = (s != null && s > max) ? s : max;
    else
      max = (s != null && f.call(s, max) > 0) ? s : max;
  }
  return max;
}

fan.sys.List.prototype.min = function(f)
{
  if (f === undefined) f = null;
  if (this.m_size == 0) return null;
  var min = this.m_values[0];
  for (var i=1; i<this.m_size; ++i)
  {
    var s = this.m_values[i];
    if (f == null)
      min = (s == null || s < min) ? s : min;
    else
      min = (s == null || f.call(s, min) < 0) ? s : min;
  }
  return min;
}

fan.sys.List.prototype.unique = function()
{
  var dups = fan.sys.Map.make(fan.sys.Obj.$type, fan.sys.Obj.$type);
  var acc = fan.sys.List.make(this.m_of);
  for (var i=0; i<this.m_size; ++i)
  {
    var v = this.m_values[i];
    var key = v;
    if (key == null) key = "__null_key__";
    if (dups.get(key) == null)
    {
      dups.set(key, this);
      acc.add(v);
    }
  }
  return acc;
}

fan.sys.List.prototype.union = function(that)
{
  var dups = fan.sys.Map.make(fan.sys.Obj.$type, fan.sys.Obj.$type);
  var acc = fan.sys.List.make(this.m_of);

  // first me
  for (var i=0; i<this.m_size; ++i)
  {
    var v = this.m_values[i];
    var key = v;
    if (key == null) key = "__null_key__";
    if (dups.get(key) == null)
    {
      dups.set(key, this);
      acc.add(v);
    }
  }

  // then him
  for (var i=0; i<that.m_size; ++i)
  {
    var v = that.m_values[i];
    var key = v;
    if (key == null) key = "__null_key__";
    if (dups.get(key) == null)
    {
      dups.set(key, this);
      acc.add(v);
    }
  }

  return acc;
}

fan.sys.List.prototype.intersection = function(that)
{
  // put other list into map
  var dups = fan.sys.Map.make(fan.sys.Obj.$type, fan.sys.Obj.$type);
  for (var i=0; i<that.m_size; ++i)
  {
    var v = that.m_values[i];
    var key = v;
    if (key == null) key = "__null_key__";
    dups.set(key, this);
  }

  // now walk this list and accumulate
  // everything found in the dups map
  var acc = fan.sys.List.make(this.m_of);
  for (var i=0; i<this.m_size; ++i)
  {
    var v = this.m_values[i];
    var key = v;
    if (key == null) key = "__null_key__";
    if (dups.get(key) != null)
    {
      acc.add(v);
      dups.remove(key);
    }
  }
  return acc;
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.sort = function(f)
{
  this.modify();
  if (f === undefined) f = null;
  if (f != null)
    this.m_values.sort(function(a,b) { return f.call(a,b) });
  else
    this.m_values.sort();
  return this;
}

fan.sys.List.prototype.sortr = function(f)
{
  this.modify();
  if (f === undefined) f = null;
  if (f != null)
    this.m_values.sort(function(a,b) { return f.call(b,a) });
  else
    this.m_values.sort().reverse();
  return this;
}

fan.sys.List.prototype.moveTo = function(item, toIndex)
{
  this.modify();
  var curIndex = this.index(item);
  if (curIndex == null) return this;
  if (curIndex == toIndex) return this;
  this.removeAt(curIndex);
  if (toIndex == -1) return this.add(item);
  if (toIndex < 0) ++toIndex;
  return this.insert(toIndex, item);
}

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.join = function(sep, f)
{
  if (sep === undefined) sep = "";
  if (f === undefined) f = null;

  if (this.m_size === 0) return "";
  if (this.m_size === 1)
  {
    var v = this.m_values[0];
    if (f != null) return f.call(v, 0);
    if (v == null) return "null";
    return fan.sys.ObjUtil.toStr(v);
  }

  var s = ""
  for (var i=0; i<this.m_size; ++i)
  {
    if (i > 0) s += sep;
    if (f == null)
      s += this.m_values[i];
    else
      s += f.call(this.m_values[i], i);
  }
  return s;
}

fan.sys.List.prototype.toStr = function()
{
  if (this.m_size == 0) return "[,]";
  var s = "[";
  for (var i=0; i<this.m_size; i++)
  {
    if (i > 0) s += ", ";
    s += this.m_values[i];
  }
  s += "]";
  return s;
}

fan.sys.List.prototype.toCode = function()
{
  var s = '';
  s += this.m_of.signature();
  s += '[';
  if (this.m_size == 0) s += ',';
  for (var i=0; i<this.m_size; ++i)
  {
    if (i > 0) s += ', ';
    s += fan.sys.ObjUtil.trap(this.m_values[i], "toCode", null);
  }
  s += ']';
  return s;
}

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

fan.sys.List.prototype.isRW = function()
{
  return !this.m_readonly;
}

fan.sys.List.prototype.isRO = function()
{
  return this.m_readonly;
}

fan.sys.List.prototype.rw = function()
{
  if (!this.m_readonly) return this;

  var rw = fan.sys.List.make(this.m_of, this.m_values.slice(0));
  rw.m_readonly = false;
  rw.m_readonlyList = this;
  return rw;
}

fan.sys.List.prototype.ro = function()
{
  if (this.m_readonly) return this;
  if (this.m_readonlyList == null)
  {
    var ro = fan.sys.List.make(this.m_of, this.m_values.slice(0));
    ro.m_readonly = true;
    this.m_readonlyList = ro;
  }
  return this.m_readonlyList;
}

fan.sys.List.prototype.isImmutable = function()
{
  return this.m_immutable;
}

fan.sys.List.prototype.toImmutable = function()
{
  if (this.m_immutable) return this;

  // make safe copy
  var temp = [];
  for (var i=0; i<this.m_size; ++i)
  {
    var item = this.m_values[i];
    if (item != null)
    {
      if (item instanceof fan.sys.List) item = item.toImmutable();
      else if (item instanceof fan.sys.Map) item = item.toImmutable();
      else if (!fan.sys.ObjUtil.isImmutable(item))
        throw fan.sys.NotImmutableErr.make("Item [" + i + "] not immutable " +
          fan.sys.Type.of(item));
    }
    temp[i] = item;
  }

  // return new immutable list
  var ro = fan.sys.List.make(this.m_of, temp);
  ro.m_readonly = true;
  ro.m_immutable = true;
  return ro;
}

fan.sys.List.prototype.modify = function()
{
  // if readonly then throw readonly exception
  if (this.m_readonly)
    throw fan.sys.ReadonlyErr.make("List is readonly");

  // if we have a cached readonlyList, then detach
  // it so it remains immutable
  if (this.m_readonlyList != null)
  {
    this.m_readonlyList.m_values = this.m_values.slice(0);
    this.m_readonlyList = null;
  }
}

