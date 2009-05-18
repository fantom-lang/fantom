//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//

/**
 * Obj is the base class for all Fan types.
 */
var sys_Obj = Class.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},
  $make: function() {},

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  equals: function(that)
  {
    return this == that;
  },

  compare: function(that)
  {
    if (this < that) return -1;
    if (this > that) return 1;
    return 0;
  },

  $with: function(func)
  {
    func(this);
  },

  isImmutable: function()
  {
    return false;
  },

  type: function()
  {
    return sys_Type.find("sys::Obj")
  },

  toStr: function()
  {
    return "" + this.type();
  },

  toString: function()
  {
    return "" + this.toStr();
  }

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Obj.equals = function(self, that)
{
  if (self instanceof sys_Obj)
    return self.equals(that);
  else if ((typeof self) == "number")
    return sys_Float.equals(self, that);
  else if (self != null && self.constructor == Array)
    return sys_List.equals(self, that);
  else
  {
    if (self != null && self.$fanType != null)
      return sys_Int.equals(self, that);
    else
      return self == that;
   }
}

sys_Obj.compare = function(self, that)
{
  if (self instanceof sys_Obj)
  {
    if (that == null) return +1;
    return self.compare(that);
  }
  else if ((typeof self) == "number")
  {
    return sys_Float.compare(self, that);
  }
  else
  {
    if (self == null)
    {
      if (that != null) return -1;
      return 0;
    }
    if (that == null) return 1;
    if (self < that) return -1;
    if (self > that) return 1;
    return 0;
  }
}

sys_Obj.is = function(obj, type)
{
  return sys_Obj.type(obj).is(type);
}

sys_Obj.as = function(obj, type)
{
  if (sys_Obj.type(obj).is(type)) return obj;
  return null;
}

sys_Obj.isImmutable = function(self)
{
  if (self instanceof sys_Obj)
    return self.isImmutable();
  else
  {
    if ((typeof self) == "boolean") return true;
    if ((typeof self) == "number") return true;
// TODO
    if (self != null && self.$fanType != null) return true;
    throw new sys_Err("sys::Obj.isImmutable: Not a Fan type: " + self);
  }
}

sys_Obj.type = function(self)
{
  if (self == null) throw sys_Err.make("sys_Obj.type: self is null");
  if (self instanceof sys_Obj)
    return self.type();
  else
    return sys_Type.toFanType(self);
}

sys_Obj._toStr = function(obj)
{
  if (obj == null) return "null";
  if (typeof obj == "string") return obj;
  if (obj.constructor == Array) return sys_List.toStr(obj);
  return obj.toString();
}

sys_Obj.echo = function(str)
{
  println(sys_Obj._toStr(str));
}