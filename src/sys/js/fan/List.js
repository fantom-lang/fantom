//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * List
 */
fan.sys.List = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.List.prototype.$ctor = function() {}
fan.sys.List.prototype.type = function()  { return fan.sys.Type.find("sys::List"); }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

fan.sys.List.make = function(type, vals)
{
  vals.$fanType = new fan.sys.ListType(type);
  return vals;
}

//////////////////////////////////////////////////////////////////////////
// Indentity
//////////////////////////////////////////////////////////////////////////

fan.sys.List.equals = function(self, that)
{
  if (that != null && that.constructor == Array)
  {
    // self.of ?= that.of
    if (self.length != that.length) return false;
    for (var i=0; i<self.length; i++)
      if (!fan.sys.Obj.equals(self[i], that[i]))
        return false;
    return true;
  }
  return false;
}

fan.sys.List.toStr = function(self)
{
  if (self.length == 0) return "[,]";
  var s = "[";
  for (var i=0; i<self.length; i++)
  {
    if (i > 0) s += ", ";
    s += self[i];
  }
  s += "]";
  return s;
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.List.isEmpty = function(self)
{
  return self.length == 0;
}

fan.sys.List.add = function(self, item)
{
  self.push(item);
  return self;
}

fan.sys.List.addAll = function(self, list)
{
  for (var i=0; i<list.length; i++)
    self.push(list[i]);
  return self;
}

fan.sys.List.insert = function(self, index, item)
{
  self.splice(index, 0, item);
  return self;
}

fan.sys.List.removeSame = function(self, val)
{
  var index = fan.sys.List.indexSame(self, val);
  if (index == null) return null;
  return fan.sys.List.removeAt(self, index);
}

fan.sys.List.removeAt = function(self, index)
{
  return self.splice(index, 1);
}

fan.sys.List.clear = function(self)
{
  self.splice(0, self.length);
  return self;
}

fan.sys.List.fill = function(self, val, times)
{
  for (var i=0; i<times; i++) self.push(val);
  return self;
}

fan.sys.List.slice = function(self, range)
{
  var size = self.length;
  var s = range.$start(size);
  var e = range.$end(size);
  if (e+1 < s) throw new fan.sys.IndexErr(r);
  return self.slice(s, e+1);
}

fan.sys.List.contains = function(self, val)
{
  return fan.sys.List.index(self, val) != null;
}

fan.sys.List.sort = function(self, func)
{
  if (func != null)
    return self.sort(func);
  else
    return self.sort();
}

fan.sys.List.index = function(self, val, off)
{
  if (off == undefined) off = 0;

  if (self.length == 0) return null;
  var start = off;
  if (start < 0) start = self.length + start;
  if (start >= self.length) throw fan.sys.IndexErr.make(off);

  try
  {
    if (val == null)
    {
      for (var i=start; i<sef.length; ++i)
        if (self[i] == null)
          return i;
    }
    else
    {
      for (var i=start; i<self.length; ++i)
      {
        var obj = self[i];
        if (obj != null && fan.sys.Obj.equals(obj, val))
          return i;
      }
    }
    return null;
  }
  // TODO
  //catch (ArrayIndexOutOfBoundsException e)
  catch (err)
  {
    throw fan.sys.IndexErr.make(off);
  }
}

fan.sys.List.indexSame = function(self, val, off)
{
  if (off == undefined) off = 0;

  if (self.length == 0) return null;
  var start = off;
  if (start < 0) start = self.length + start;
  if (start >= self.length) throw fan.sys.IndexErr.make(off);

  try
  {
    for (var i=start; i<self.length; i++)
      if (val == self[i])
        return i;
    return null;
  }
  // TODO
  //catch (ArrayIndexOutOfBoundsException e)
  catch (err)
  {
    throw fan.sys.IndexErr.make(off);
  }
}

fan.sys.List.first = function(self)
{
  if (self.length == 0) return null;
  return self[0];
}

fan.sys.List.last = function(self)
{
  if (self.length == 0) return null;
  return self[self.length-1];
}

fan.sys.List.dup = function(self)
{
  return fan.sys.List.make(self.$fanType, self.slice(0));
}

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

fan.sys.List.peek = function(self)
{
  if (self.length == 0) return null;
  return self[self.length-1];
}

fan.sys.List.pop = function(self)
{
  // modify in removeAt()
  if (self.length == 0) return null;
  return fan.sys.List.removeAt(self, -1);
}

fan.sys.List.push = function(self, obj)
{
  // modify in add()
  return sys.fan.List.add(self, obj);
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.List.each = function(self, func)
{
  if (func.length == 1)
  {
    for (var i=0; i<self.length; i++)
      func(self[i])
  }
  else
  {
    for (var i=0; i<self.length; i++)
      func(self[i], i)
  }
}

fan.sys.List.eachr = function(self, func)
{
  if (func.length == 1)
  {
    for (var i=self.length-1; i>=0; i--)
      func(self[i])
  }
  else
  {
    for (var i=self.length-1; i>=0; i--)
      func(self[i], i)
  }
}

fan.sys.List.eachWhile = function(self, f)
{
  if (f.length == 1)
  {
    for (var i=0; i<self.length; ++i)
    {
      var r = f(self[i]);
      if (r != null) return r;
    }
  }
  else
  {
    for (var i=0; i<self.length; ++i)
    {
      var r = f(self[i], i);
      if (r != null) return r;
    }
  }
  return null;
}

fan.sys.List.find = function(self, f)
{
  if (f.length == 1)
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i]) == true)
        return self[i];
  }
  else
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i], i) == true)
        return self[i];
  }
  return null;
}

fan.sys.List.findIndex = function(self, f)
{
  if (f.length == 1)
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i]) == true)
        return i;
  }
  else
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i], i) == true)
        return i;
  }
  return null;
}

fan.sys.List.findAll = function(self, f)
{
  var v = self.$fanType.v;
  var acc = fan.sys.List.make(v, []);
  if (f.length == 1)
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i]) == true)
        acc.push(self[i]);
  }
  else
  {
    for (var i=0; i<self.length; i++)
      if (f(self[i], i) == true)
        acc.push(self[i]);
  }
  return acc;
}

fan.sys.List.map = function(self, f)
{
  var r = f.$fanType.ret;
  // if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
  var acc = fan.sys.List.make(r, []);
  if (f.length == 1)
  {
    for (var i=0; i<self.length; ++i)
      acc.push(f(self[i]));
  }
  else
  {
    for (var i=0; i<self.length; ++i)
      acc.push(f(self[i], i));
  }
  return acc;
}

fan.sys.List.max = function(self, f)
{
  if (f == undefined) f = null;
  if (self.length == 0) return null;
  var max = self[0];
  for (var i=1; i<self.length; ++i)
  {
    var s = self[i];
    if (f == null)
      max = (s != null && s > max) ? s : max;
    else
      max = (s != null && f(s, max) > 0) ? s : max;
  }
  return max;
}

fan.sys.List.min = function(self, f)
{
  if (f == undefined) f = null;
  if (self.length == 0) return null;
  var min = self[0];
  for (var i=1; i<self.length; ++i)
  {
    var s = self[i];
    if (f == null)
      min = (s == null || s < min) ? s : min;
    else
      min = (s == null || f(s, min) < 0) ? s : min;
  }
  return min;
}

// TODO
fan.sys.List.rw = function(self) { return fan.sys.List.make(self.$fanType, self.slice(0)); }
fan.sys.List.ro = function(self) { return fan.sys.List.make(self.$fanType, self.slice(0)); }
fan.sys.List.toImmutable = function(self) { return fan.sys.List.make(self.$fanType, self.slice(0)); }

// Conversion
fan.sys.List.join = function(self, sep, func)
{
  if (sep == undefined) sep = ""
  if (self.length == 0) return "";
  if (self.length == 1)
  {
    var v = self[0];
    if (func != undefined) return func(v, 0);
    if (v == null) return "null";
    return fan.sys.Obj.toStr(v);
  }

  var s = ""
  for (var i=0; i<self.length; ++i)
  {
    if (i > 0) s += sep;
    if (func == undefined)
      s += self[i];
    else
      s += func(self[i], i);
  }
  return s;
}