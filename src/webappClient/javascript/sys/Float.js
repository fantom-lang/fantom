//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 08  Andy Frank  Creation
//

/**
 * Float
 */
var sys_Float = sys_Num.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::Float");
  }

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

// Identity
sys_Float.equals = function(self, that)
{
  if ((typeof self) == "number")
  {
    if (isNaN(self)) return isNaN(that);
    return self == that;
  }
  return false;
}
sys_Float.compare = function(self, that)
{
  if (self == null) return that == null ? 0 : -1;
  if (that == null) return 1;
  if (isNaN(self)) return isNaN(that) ? 0 : -1;
  if (isNaN(that)) return 1;
  if (self < that) return -1; return self == that ? 0 : 1;
}

// Math
sys_Float.abs = function(self) { return Math.abs(self); }
sys_Float.approx = function(self, that, tolerance)
{
  // need this to check +inf, -inf, and nan
  if (sys_Obj.equals(self, that)) return true;
  var t = tolerance == null
    ? Math.min(Math.abs(self/1e6), Math.abs(that/1e6))
    : tolerance;
  return Math.abs(self - that) <= t;
}
sys_Float.ceil  = function(self) { return Math.ceil(self); }
sys_Float.exp   = function(self) { return Math.exp(self); }
sys_Float.floor = function(self) { return Math.floor(self); }
sys_Float.log   = function(self) { return Math.log(self); }
sys_Float.min   = function(self, that) { return Math.min(self, that); }
sys_Float.max   = function(self, that) { return Math.max(self, that); }
sys_Float.pow   = function(self, exp) { return Math.pow(self, exp); }
sys_Float.round = function(self) { return Math.round(self); }
sys_Float.sqrt  = function(self) { return Math.sqrt(self); }

// Trig
sys_Float.acos  = function(self) { return Math.acos(self); }
sys_Float.asin  = function(self) { return Math.asin(self); }
sys_Float.atan  = function(self) { return Math.atan(self); }
sys_Float.atan2 = function(y, x) { return Math.atan2(y, x); }
sys_Float.cos   = function(self) { return Math.cos(self); }
sys_Float.sin   = function(self) { return Math.sin(self); }
sys_Float.tan   = function(self) { return Math.tan(self); }
sys_Float.toDegrees = function(self) { return self * 180 / Math.PI; }
sys_Float.toRadians = function(self) { return self * Math.PI / 180; }

// Str
sys_Float.fromStr = function(s, checked)
{
  if (s == "NaN") return Number.NaN;
  if (s == "INF") return Number.POSITIVE_INFINITY;
  if (s == "-INF") return Number.NEGATIVE_INFINITY;
  var num = parseFloat(s);
  if (isNaN(num))
  {
    if (checked != null && !checked) return null;
    throw new sys_ParseErr("Float", s);
  }
  return num;
}
sys_Float.toStr = function(self)
{
  if (isNaN(self)) return "NaN";
  if (self == Number.POSITIVE_INFINITY) return "INF";
  if (self == Number.NEGATIVE_INFINITY) return "-INF";
  return ""+self;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

sys_Float.posInf = Number.POSITIVE_INFINITY;
sys_Float.negInf = Number.NEGATIVE_INFINITY;
sys_Float.nan    = Number.NaN;
sys_Float.e      = Math.E;
sys_Float.pi     = Math.PI;