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
  var arr = fan.sys.Month.m_values;
  return arr[(this.m_ordinal+1) % arr.length];
}

fan.sys.Month.prototype.decrement = function()
{
  var arr = fan.sys.Month.m_values;
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

// TODO FIXIT
fan.sys.Month.prototype.localeAbbr = function() { return this.abbr(null); }
fan.sys.Month.prototype.abbr = function(locale)
{
  switch (this.m_ordinal)
  {
    case 0:  return "Jan";
    case 1:  return "Feb";
    case 2:  return "Mar";
    case 3:  return "Apr";
    case 4:  return "May";
    case 5:  return "Jun";
    case 6:  return "Jul";
    case 7:  return "Aug";
    case 8:  return "Sep";
    case 9:  return "Oct";
    case 10: return "Nov";
    case 11: return "Dec";
  }
}

// TODO FIXIT
fan.sys.Month.prototype.localeFull = function() { return this.abbr(null); }
fan.sys.Month.prototype.full = function(locale)
{
  switch (this.m_ordinal)
  {
    case 0:  return "January";
    case 1:  return "February";
    case 2:  return "March";
    case 3:  return "April";
    case 4:  return "May";
    case 5:  return "June";
    case 6:  return "July";
    case 7:  return "August";
    case 8:  return "September";
    case 9:  return "October";
    case 10: return "November";
    case 11: return "December";
  }
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Month.m_jan = new fan.sys.Month(0,  "jan");
fan.sys.Month.m_feb = new fan.sys.Month(1,  "feb");
fan.sys.Month.m_mar = new fan.sys.Month(2,  "mar");
fan.sys.Month.m_apr = new fan.sys.Month(3,  "apr");
fan.sys.Month.m_may = new fan.sys.Month(4,  "may");
fan.sys.Month.m_jun = new fan.sys.Month(5,  "jun");
fan.sys.Month.m_jul = new fan.sys.Month(6,  "jul");
fan.sys.Month.m_aug = new fan.sys.Month(7,  "aug");
fan.sys.Month.m_sep = new fan.sys.Month(8,  "sep");
fan.sys.Month.m_oct = new fan.sys.Month(9,  "oct");
fan.sys.Month.m_nov = new fan.sys.Month(10, "nov");
fan.sys.Month.m_dec = new fan.sys.Month(11, "dec");

// values defined in sysPod.js

