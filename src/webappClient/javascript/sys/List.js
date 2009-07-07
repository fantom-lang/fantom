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
var sys_List = sys_Obj.$extend(sys_Obj);

sys_List.prototype.$ctor = function() {}
sys_List.prototype.type = function()  { return sys_Type.find("sys::List"); }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

sys_List.make = function(type, vals)
{
  vals.$fanType = new sys_ListType(type);
  return vals;
}

//////////////////////////////////////////////////////////////////////////
// Indentity
//////////////////////////////////////////////////////////////////////////

sys_List.equals = function(self, that)
{
  if (that != null && that.constructor == Array)
  {
    // self.of ?= that.of
    if (self.length != that.length) return false;
    for (var i=0; i<self.length; i++)
      if (!sys_Obj.equals(self[i], that[i]))
        return false;
    return true;
  }
  return false;
}

sys_List.toStr = function(self)
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

sys_List.add = function(self, item)
{
  self.push(item);
  return self;
}

sys_List.addAll = function(self, list)
{
  return sys_List.make(self.$fanType, self.concat(list));
}

sys_List.insert = function(self, index, item)
{
  self.splice(index, 0, item);
  return self;
}

sys_List.removeSame = function(self, val)
{
  var index = sys_List.indexSame(self, val);
  if (index == null) return null;
  return sys_List.removeAt(self, index);
}

sys_List.removeAt = function(self, index)
{
  return self.splice(index, 1);
}

sys_List.clear = function(self)
{
  self.splice(0, self.length);
  return self;
}

sys_List.fill = function(self, val, times)
{
  for (var i=0; i<times; i++) self.push(val);
  return self;
}

sys_List.slice = function(self, range)
{
  var size = self.length;
  var s = range.start(size);
  var e = range.end(size);
  if (e+1 < s) throw new sys_IndexErr(r);
  return self.slice(s, e+1);
}

sys_List.sort = function(self, func)
{
  if (func != null)
    return self.sort(func);
  else
    return self.sort();
}

sys_List.indexSame = function(self, val, off)
{
  if (off == undefined) off = 0;

  if (self.length == 0) return null;
  var start = off;
  if (start < 0) start = self.length + start;
  if (start >= self.length) throw sys_IndexErr.make(off);

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
    throw sys_IndexErr.make(off);
  }
}

sys_List.first = function(self)
{
  if (self.length == 0) return null;
  return self[0];
}

sys_List.last = function(self)
{
  if (self.length == 0) return null;
  return self[self.length-1];
}

sys_List.dup = function(self)
{
  return sys_List.make(self.$fanType, self.slice());
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

sys_List.each = function(self, func)
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

sys_List.eachr = function(self, func)
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

sys_List.find = function(self, f)
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

sys_List.map = function(self, f)
{
  var r = f.$fanType.ret;
  // if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
  var acc = sys_List.make(r, []);
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

sys_List.max = function(self, f)
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

sys_List.min = function(self, f)
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
sys_List.rw = function(self) { return sys_List.make(self.$fanType, self.slice()); }
sys_List.ro = function(self) { return sys_List.make(self.$fanType, self.slice()); }
sys_List.toImmutable = function(self) { return sys_List.make(self.$fanType, self.slice()); }

// Conversion
sys_List.join = function(self, sep, func)
{
  if (sep == undefined) sep = ""
  if (self.length == 0) return "";
  if (self.length == 1)
  {
    var v = self[0];
    if (func != undefined) return func(v, 0);
    if (v == null) return "null";
    return sys_Obj.toStr(v);
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