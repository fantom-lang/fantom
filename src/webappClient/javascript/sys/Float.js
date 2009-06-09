//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Float
 */
var sys_Float = sys_Obj.$extend(sys_Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Float.prototype.$ctor = function() {}

sys_Float.make = function(val)
{
  var x = new Number(val);
  x.$fanType = sys_Type.find("sys::Float");
  return x;
}

sys_Float.prototype.type = function()
{
  return sys_Type.find("sys::Float");
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_Float.equals = function(self, that)
{
  if (that != null && self.$fanType == that.$fanType)
  {
    if (isNaN(self) || isNaN(that)) return false;
    return self.valueOf() == that.valueOf();
  }
  return false;
}

sys_Float.compare = function(self, that)
{
  if (self == null) return that == null ? 0 : -1;
  if (that == null) return 1;
  if (isNaN(self)) return isNaN(that) ? 0 : -1;
  if (isNaN(that)) return 1;
  if (self < that) return -1; return self.valueOf() == that.valueOf() ? 0 : 1;
}

//////////////////////////////////////////////////////////////////////////
// Math
//////////////////////////////////////////////////////////////////////////

sys_Float.abs = function(self) { return Math.abs(self); }
sys_Float.approx = function(self, that, tolerance)
{
  // need this to check +inf, -inf, and nan
  if (sys_Float.equals(self, that)) return true;
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

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

sys_Float.fromStr = function(s, checked)
{
  if (s == "NaN") return sys_Float.nan;
  if (s == "INF") return sys_Float.posInf;
  if (s == "-INF") return sys_Float.negInf;
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
  if (self == sys_Float.posInf) return "INF";
  if (self == sys_Float.negInf) return "-INF";
  return ""+self;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// TEMP - see sysPod.js
//sys_Float.posInf = sys_Float.make(Number.POSITIVE_INFINITY);
//sys_Float.negInf = sys_Float.make(Number.NEGATIVE_INFINITY);
//sys_Float.nan    = sys_Float.make(Number.NaN);
//sys_Float.e      = sys_Float.make(Math.E);
//sys_Float.pi     = sys_Float.make(Math.PI);