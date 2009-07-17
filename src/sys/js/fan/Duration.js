//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Duration
 */
fan.sys.Duration = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.$ctor = function(ticks)
{
  this.m_ticks = ticks;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Duration)
    return this.m_ticks == that.m_ticks;
  else
    return false;
}

fan.sys.Duration.prototype.compare = function(that)
{
  if (this.m_ticks < that.m_ticks) return -1;
  if (this.m_ticks == that.m_ticks) return 0;
  return +1;
}

fan.sys.Duration.prototype.type = function()
{
  return fan.sys.Type.find("sys::Duration");
}

fan.sys.Duration.prototype.ticks = function()
{
  return this.m_ticks;
}

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.negate = function() { return fan.sys.Duration.make(-this.m_ticks); }
fan.sys.Duration.prototype.plus = function(x)  { return fan.sys.Duration.make(this.m_ticks + x.m_ticks); }
fan.sys.Duration.prototype.minus = function(x) { return fan.sys.Duration.make(this.m_ticks - x.m_ticks); }
fan.sys.Duration.prototype.mult = function(x)  { return fan.sys.Duration.make(this.m_ticks * x); }
fan.sys.Duration.prototype.div = function(x)   { return fan.sys.Duration.make(this.m_ticks / x); }
fan.sys.Duration.prototype.floor = function(accuracy)
{
  if (this.m_ticks % accuracy.m_ticks == 0) return this;
  return fan.sys.Duration.make(this.m_ticks - (this.m_ticks % accuracy.m_ticks));
}
fan.sys.Duration.prototype.abs = function()
{
  if (this.m_ticks >= 0) return this;
  return new fan.sys.Duration(-this.m_ticks);
}

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.toStr = function()
{
  if (this.m_ticks == 0) return "0ns";

  // if clean millisecond boundary
  var ns = this.m_ticks;
  if (ns % fan.sys.Duration.nsPerMilli == 0)
  {
    if (ns % fan.sys.Duration.nsPerDay == 0) return ns/fan.sys.Duration.nsPerDay + "day";
    if (ns % fan.sys.Duration.nsPerHr  == 0) return ns/fan.sys.Duration.nsPerHr  + "hr";
    if (ns % fan.sys.Duration.nsPerMin == 0) return ns/fan.sys.Duration.nsPerMin + "min";
    if (ns % fan.sys.Duration.nsPerSec == 0) return ns/fan.sys.Duration.nsPerSec + "sec";
    return ns/fan.sys.Duration.nsPerMilli + "ms";
  }

  // return in nanoseconds
  return ns + "ns";
}

fan.sys.Duration.prototype.toCode = function() { return this.toStr(); }

fan.sys.Duration.prototype.toMillis = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerMilli); }
fan.sys.Duration.prototype.toSec    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerSec); }
fan.sys.Duration.prototype.toMin    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerMin); }
fan.sys.Duration.prototype.toHour   = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerHr); }
fan.sys.Duration.prototype.toDay    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerDay); }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.make = function(ticks)
{
  return new fan.sys.Duration(ticks);
}

fan.sys.Duration.makeMillis = function(ms)
{
  return fan.sys.Duration.make(ms*1000000);
}

fan.sys.Duration.fromStr = function(s, checked)
{
  //   ns:   nanoseconds  (x 1)
  //   ms:   milliseconds (x 1,000,000)
  //   sec:  seconds      (x 1,000,000,000)
  //   min:  minutes      (x 60,000,000,000)
  //   hr:   hours        (x 3,600,000,000,000)
  //   day:  days         (x 86,400,000,000,000)
  try
  {
    var len = s.length;
    var x1  = s.charAt(len-1);
    var x2  = s.charAt(len-2);
    var x3  = s.charAt(len-3);
    var dot = s.indexOf('.') > 0;

    var mult = -1;
    var suffixLen  = -1;
    switch (x1)
    {
      case 's':
        if (x2 == 'n') { mult=1; suffixLen=2; } // ns
        if (x2 == 'm') { mult=1000000; suffixLen=2; } // ms
        break;
      case 'c':
        if (x2 == 'e' && x3 == 's') { mult=1000000000; suffixLen=3; } // sec
        break;
      case 'n':
        if (x2 == 'i' && x3 == 'm') { mult=60000000000; suffixLen=3; } // min
        break;
      case 'r':
        if (x2 == 'h') { mult=3600000000000; suffixLen=2; } // hr
        break;
      case 'y':
        if (x2 == 'a' && x3 == 'd') { mult=86400000000000; suffixLen=3; } // day
        break;
    }

    if (mult < 0) throw new Error();

    s = s.substring(0, len-suffixLen);
    if (dot)
    {
      var num = parseFloat(s);
      if (isNaN(num)) throw new Error();
      return new fan.sys.Duration(Math.floor(num*mult));
    }
    else
    {
      var num = fan.sys.Int.fromStr(s);
      return new fan.sys.Duration(num*mult);
    }
  }
  catch (err)
  {
    if (checked != null && !checked) return null;
    throw new fan.sys.ParseErr("Duration", s);
  }
}

fan.sys.Duration.now = function()
{
  var ms = new Date().getTime();
  return new fan.sys.Duration(ms * fan.sys.Duration.nsPerMilli);
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.nsPerDay   = 86400000000000;
fan.sys.Duration.nsPerHr    = 3600000000000;
fan.sys.Duration.nsPerMin   = 60000000000;
fan.sys.Duration.nsPerSec   = 1000000000;
fan.sys.Duration.nsPerMilli = 1000000;
fan.sys.Duration.secPerDay  = 86400;
fan.sys.Duration.secPerHr   = 3600;
fan.sys.Duration.secPerMin  = 60;

fan.sys.Duration.defVal    = new fan.sys.Duration(0);
fan.sys.Duration.minVal    = new fan.sys.Duration(fan.sys.Int.minVal);
fan.sys.Duration.maxVal    = new fan.sys.Duration(fan.sys.Int.maxVal);
fan.sys.Duration.oneDay    = new fan.sys.Duration(fan.sys.Duration.nsPerDay);
fan.sys.Duration.negOneDay = new fan.sys.Duration(-fan.sys.Duration.nsPerDay);

