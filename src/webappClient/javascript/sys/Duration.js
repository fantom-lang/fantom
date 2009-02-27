//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 09  Andy Frank  Creation
//

/**
 * Duration
 */
var sys_Duration = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(ticks)
  {
    this.m_ticks = ticks;
  },

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals: function(that)
  {
    if (that instanceof sys_Duration)
      return this.m_ticks == that.m_ticks;
    else
      return false;
  },

  compare: function(that)
  {
    if (that == null) return +1;
    if (this.m_ticks < that.m_ticks) return -1;
    if (this.m_ticks == that.m_ticks) return 0;
    return +1;
  },

  type: function()
  {
    return sys_Type.find("sys::Duration");
  },

  toStr: function()
  {
    if (this.m_ticks == 0) return "0ns";

    // if clean millisecond boundary
    var ns = this.m_ticks;
    if (ns % sys_Duration.nsPerMilli == 0)
    {
      if (ns % sys_Duration.nsPerDay == 0) return ns/sys_Duration.nsPerDay + "day";
      if (ns % sys_Duration.nsPerHr  == 0) return ns/sys_Duration.nsPerHr  + "hr";
      if (ns % sys_Duration.nsPerMin == 0) return ns/sys_Duration.nsPerMin + "min";
      if (ns % sys_Duration.nsPerSec == 0) return ns/sys_Duration.nsPerSec + "sec";
      return ns/sys_Duration.nsPerMilli + "ms";
    }

    // return in nanoseconds
    return ns + "ns";
  },

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  negate: function() { return sys_Duration.make(-this.m_ticks); },
  plus: function(x)  { return sys_Duration.make(this.m_ticks + x.m_ticks); },
  minus: function(x) { return sys_Duration.make(this.m_ticks - x.m_ticks); },
  mult: function(x)  { return sys_Duration.make(this.m_ticks * x); },
  div: function(x)   { return sys_Duration.make(this.m_ticks / x); },
  floor: function(accuracy)
  {
    if (this.m_ticks % accuracy.m_ticks == 0) return this;
    return sys_Duration.make(this.m_ticks - (this.m_ticks % accuracy.m_ticks));
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_ticks: 0

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Duration.make = function(ticks)
{
  return new sys_Duration(ticks);
}

sys_Duration.fromStr = function(s, checked)
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
      return new sys_Duration(Math.floor(num*mult));
    }
    else
    {
      var num = sys_Int.fromStr(s);
      return new sys_Duration(num*mult);
    }
  }
  catch (err)
  {
    if (checked != null && !checked) return null;
    throw new sys_ParseErr("Duration", s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

sys_Duration.nsPerDay   = 86400000000000;
sys_Duration.nsPerHr    = 3600000000000;
sys_Duration.nsPerMin   = 60000000000;
sys_Duration.nsPerSec   = 1000000000;
sys_Duration.nsPerMilli = 1000000;
sys_Duration.secPerDay  = 86400;
sys_Duration.secPerHr   = 3600;
sys_Duration.secPerMin  = 60;

sys_Duration.defVal = new sys_Duration(0);