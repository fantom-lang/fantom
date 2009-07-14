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
  var arr = fan.sys.Weekday.values;
  return arr[(this.m_ordinal+1) % arr.length];
}

fan.sys.Weekday.prototype.decrement = function()
{
  var arr = fan.sys.Weekday.values;
  return this.m_ordinal == 0 ? arr[arr.length-1] : arr[this.m_ordinal-1];
}

fan.sys.Weekday.prototype.type = function()
{
  return fan.sys.Type.find("sys::Weekday");
}

// TODO FIXIT
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

fan.sys.Weekday.sun = new fan.sys.Weekday(0,  "sun");
fan.sys.Weekday.mon = new fan.sys.Weekday(1,  "mon");
fan.sys.Weekday.tue = new fan.sys.Weekday(2,  "tue");
fan.sys.Weekday.wed = new fan.sys.Weekday(3,  "wed");
fan.sys.Weekday.thu = new fan.sys.Weekday(4,  "thu");
fan.sys.Weekday.fri = new fan.sys.Weekday(5,  "fri");
fan.sys.Weekday.sat = new fan.sys.Weekday(6,  "sat");

fan.sys.Weekday.values =
[
  fan.sys.Weekday.sun,
  fan.sys.Weekday.mon,
  fan.sys.Weekday.tue,
  fan.sys.Weekday.wed,
  fan.sys.Weekday.thu,
  fan.sys.Weekday.fri,
  fan.sys.Weekday.sat
];