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
var sys_Month = sys_Obj.$extend(sys_Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Month.prototype.$ctor = function(ordinal, name)
{
  this.$make(ordinal, name);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Month.prototype.increment = function()
{
  var arr = sys_Month.values;
  return arr[(this.m_ordinal+1) % arr.length];
}

sys_Month.prototype.decrement = function()
{
  var arr = sys_Month.values;
  return this.m_ordinal == 0 ? arr[arr.length-1] : arr[this.m_ordinal-1];
}

sys_Month.prototype.numDays = function(year)
{
  if (sys_DateTime.isLeapYear(year))
    return sys_DateTime.daysInMonLeap[this.m_ordinal];
  else
    return sys_DateTime.daysInMon[this.m_ordinal];
}

sys_Month.prototype.type = function()
{
  return sys_Type.find("sys::Month");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Month.jan = new sys_Month(0,  "jan");
sys_Month.feb = new sys_Month(1,  "feb");
sys_Month.mar = new sys_Month(2,  "mar");
sys_Month.apr = new sys_Month(3,  "apr");
sys_Month.may = new sys_Month(4,  "may");
sys_Month.jun = new sys_Month(5,  "jun");
sys_Month.jul = new sys_Month(6,  "jul");
sys_Month.aug = new sys_Month(7,  "aug");
sys_Month.sep = new sys_Month(8,  "sep");
sys_Month.oct = new sys_Month(9,  "oct");
sys_Month.nov = new sys_Month(10, "nov");
sys_Month.dec = new sys_Month(11, "dec");

// values defined in sysPod.js

