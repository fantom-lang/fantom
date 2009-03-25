//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

/**
 * List
 */
var sys_List = sys_Obj.extend(
{
  $ctor: function() { sys_Type.addType("sys::List"); },
  type: function()  { return sys_Type.find("sys::List"); }
});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

// Identity
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
// Items
sys_List.add = function(self, item)
{
  self.push(item);
  return self;
}
sys_List.insert = function(self, index, item)
{
  self.splice(index, 0, item);
  return self;
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
// Iterators
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
sys_List.map = function(self, acc, func)
{
  if (func.length == 1)
  {
    for (var i=0; i<self.length; ++i)
      acc.push(func(self[i]));
  }
  else
  {
    for (var i=0; i<self.length; ++i)
      acc.push(func(self[i], i));
  }
  return acc;
}
sys_List.toImmutable = function(self)
{
  // TODO
  return self;
}