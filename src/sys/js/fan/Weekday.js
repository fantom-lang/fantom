//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Weekday
 */
fan.sys.Weekday = fan.sys.Obj.$extend(fan.sys.Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Weekday.prototype.$ctor = function(ordinal, name)
{
  this.make$(ordinal, name);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Weekday.prototype.increment = function()
{
  var arr = fan.sys.Weekday.m_values;
  return arr[(this.m_ordinal+1) % arr.length];
}

fan.sys.Weekday.prototype.decrement = function()
{
  var arr = fan.sys.Weekday.m_values;
  return this.m_ordinal == 0 ? arr[arr.length-1] : arr[this.m_ordinal-1];
}

fan.sys.Weekday.prototype.type = function()
{
  return fan.sys.Type.find("sys::Weekday");
}

// TODO FIXIT
fan.sys.Weekday.prototype.localeAbbr = function() { return this.abbr(null); }
fan.sys.Weekday.prototype.abbr = function(locale)
{
  switch (this.m_ordinal)
  {
    case 0:  return "Sun";
    case 1:  return "Mon";
    case 2:  return "Tue";
    case 3:  return "Wed";
    case 4:  return "Thu";
    case 5:  return "Fri";
    case 6:  return "Sat";
  }
}

// TODO FIXIT
fan.sys.Weekday.prototype.localeFull = function() { return this.full(null); }
fan.sys.Weekday.prototype.full = function(locale)
{
  switch (this.m_ordinal)
  {
    case 0:  return "Sundary";
    case 1:  return "Monday";
    case 2:  return "Tuesday";
    case 3:  return "Wednesday";
    case 4:  return "Thursday";
    case 5:  return "Friday";
    case 6:  return "Saturday";
  }
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Weekday.m_sun = new fan.sys.Weekday(0,  "sun");
fan.sys.Weekday.m_mon = new fan.sys.Weekday(1,  "mon");
fan.sys.Weekday.m_tue = new fan.sys.Weekday(2,  "tue");
fan.sys.Weekday.m_wed = new fan.sys.Weekday(3,  "wed");
fan.sys.Weekday.m_thu = new fan.sys.Weekday(4,  "thu");
fan.sys.Weekday.m_fri = new fan.sys.Weekday(5,  "fri");
fan.sys.Weekday.m_sat = new fan.sys.Weekday(6,  "sat");

fan.sys.Weekday.m_values =
[
  fan.sys.Weekday.m_sun,
  fan.sys.Weekday.m_mon,
  fan.sys.Weekday.m_tue,
  fan.sys.Weekday.m_wed,
  fan.sys.Weekday.m_thu,
  fan.sys.Weekday.m_fri,
  fan.sys.Weekday.m_sat
];