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
fan.sys.Float = fan.sys.Obj.$extend(fan.sys.Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Float.prototype.$ctor = function() {}

fan.sys.Float.make = function(val)
{
  var x = new Number(val);
  x.$fanType = fan.sys.Type.find("sys::Float");
  return x;
}

fan.sys.Float.prototype.type = function()
{
  return fan.sys.Type.find("sys::Float");
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Float.equals = function(self, that)
{
  if (that != null && self.$fanType == that.$fanType)
  {
    if (isNaN(self) || isNaN(that)) return false;
    return self.valueOf() == that.valueOf();
  }
  return false;
}

fan.sys.Float.compare = function(self, that)
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

fan.sys.Float.abs = function(self) { return Math.abs(self); }
fan.sys.Float.approx = function(self, that, tolerance)
{
  // need this to check +inf, -inf, and nan
  if (fan.sys.Float.equals(self, that)) return true;
  var t = tolerance == null
    ? Math.min(Math.abs(self/1e6), Math.abs(that/1e6))
    : tolerance;
  return Math.abs(self - that) <= t;
}
fan.sys.Float.ceil  = function(self) { return Math.ceil(self); }
fan.sys.Float.exp   = function(self) { return Math.exp(self); }
fan.sys.Float.floor = function(self) { return Math.floor(self); }
fan.sys.Float.log   = function(self) { return Math.log(self); }
fan.sys.Float.log10 = function(self) { return Math.log(self) / Math.LN10; }
fan.sys.Float.min   = function(self, that) { return Math.min(self, that); }
fan.sys.Float.max   = function(self, that) { return Math.max(self, that); }
fan.sys.Float.pow   = function(self, exp) { return Math.pow(self, exp); }
fan.sys.Float.round = function(self) { return Math.round(self); }
fan.sys.Float.sqrt  = function(self) { return Math.sqrt(self); }

// Trig
fan.sys.Float.acos  = function(self) { return Math.acos(self); }
fan.sys.Float.asin  = function(self) { return Math.asin(self); }
fan.sys.Float.atan  = function(self) { return Math.atan(self); }
fan.sys.Float.atan2 = function(y, x) { return Math.atan2(y, x); }
fan.sys.Float.cos   = function(self) { return Math.cos(self); }
fan.sys.Float.sin   = function(self) { return Math.sin(self); }
fan.sys.Float.tan   = function(self) { return Math.tan(self); }
fan.sys.Float.toDegrees = function(self) { return self * 180 / Math.PI; }
fan.sys.Float.toRadians = function(self) { return self * Math.PI / 180; }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

fan.sys.Float.fromStr = function(s, checked)
{
  if (s == "NaN") return fan.sys.Float.nan;
  if (s == "INF") return fan.sys.Float.posInf;
  if (s == "-INF") return fan.sys.Float.negInf;
  // temp check till we get correct algorithm
  if (/^[0-9]+\.[0-9]+$/.test(s) == false)
  {
    if (checked != null && !checked) return null;
    throw new fan.sys.ParseErr("Float", s);
  }
  var num = parseFloat(s);
  if (isNaN(num))
  {
    if (checked != null && !checked) return null;
    throw new fan.sys.ParseErr("Float", s);
  }
  return num;
}

fan.sys.Float.toStr = function(self)
{
  if (isNaN(self)) return "NaN";
  if (self == fan.sys.Float.posInf) return "INF";
  if (self == fan.sys.Float.negInf) return "-INF";
  return ""+self;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// TEMP - see sysPod.js
//fan.sys.Float.posInf = fan.sys.Float.make(Number.POSITIVE_INFINITY);
//fan.sys.Float.negInf = fan.sys.Float.make(Number.NEGATIVE_INFINITY);
//fan.sys.Float.nan    = fan.sys.Float.make(Number.NaN);
//fan.sys.Float.e      = fan.sys.Float.make(Math.E);
//fan.sys.Float.pi     = fan.sys.Float.make(Math.PI);