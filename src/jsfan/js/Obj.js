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

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Obj.equals = function(self, that)
{
  if (self instanceof sys_Obj)
    return self.equals(that);
  else
    return self == that;
}

sys_Obj.compare = function(self, that)
{
  if (self instanceof sys_Obj)
    return self.compare(that);
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

sys_Obj.isImmutable = function(self)
{
  if (self instanceof sys_Obj)
    return self.isImmutable();
  else
  {
    if ((typeof self) == "boolean") return true;
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