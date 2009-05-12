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
  if (obj instanceof sys_Obj)
    return obj instanceof type;
  else
  {
    if ((typeof obj) == "boolean")
    {
      if (type === sys_Obj) return true;
      if (type === sys_Bool) return true;
      return false;
    }
    if ((typeof obj) == "number")
    {
      if (type === sys_Obj) return true;
      if (type === sys_Num) return true;
      //if (type === sys_Int) return true;
      if (type === sys_Float) return true;
      return false;
    }
    if ((typeof obj) == "string")
    {
      if (type === sys_Str) return true;
      return false;
    }
// TODO
    if (obj.$fanType != null)
    {
      if (type === sys_Obj) return true;
      if (type === sys_Num) return true;
      if (type === sys_Int) return true;
      return false;
    }
    throw new sys_Err("Not a Fan type: " + obj);
  }
}

sys_Obj.as = function(obj, type)
{
  if (sys_Obj.is(obj, type)) return obj;
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
    throw new sys_Err("Not a Fan type: " + self);
  }
}

sys_Obj.type = function(self)
{
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