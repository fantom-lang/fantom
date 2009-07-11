//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Month
 */
fan.sys.Month = fan.sys.Obj.$extend(fan.sys.Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Month.prototype.$ctor = function(ordinal, name)
{
  this.make$(ordinal, name);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Month.prototype.increment = function()
{
  var arr = fan.sys.Month.values;
  return arr[(this.m_ordinal+1) % arr.length];
}

fan.sys.Month.prototype.decrement = function()
{
  var arr = fan.sys.Month.values;
  return this.m_ordinal == 0 ? arr[arr.length-1] : arr[this.m_ordinal-1];
}

fan.sys.Month.prototype.numDays = function(year)
{
  if (fan.sys.DateTime.isLeapYear(year))
    return fan.sys.DateTime.daysInMonLeap[this.m_ordinal];
  else
    return fan.sys.DateTime.daysInMon[this.m_ordinal];
}

fan.sys.Month.prototype.type = function()
{
  return fan.sys.Type.find("sys::Month");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Month.jan = new fan.sys.Month(0,  "jan");
fan.sys.Month.feb = new fan.sys.Month(1,  "feb");
fan.sys.Month.mar = new fan.sys.Month(2,  "mar");
fan.sys.Month.apr = new fan.sys.Month(3,  "apr");
fan.sys.Month.may = new fan.sys.Month(4,  "may");
fan.sys.Month.jun = new fan.sys.Month(5,  "jun");
fan.sys.Month.jul = new fan.sys.Month(6,  "jul");
fan.sys.Month.aug = new fan.sys.Month(7,  "aug");
fan.sys.Month.sep = new fan.sys.Month(8,  "sep");
fan.sys.Month.oct = new fan.sys.Month(9,  "oct");
fan.sys.Month.nov = new fan.sys.Month(10, "nov");
fan.sys.Month.dec = new fan.sys.Month(11, "dec");

// values defined in sysPod.js

