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
  fan.sys.Enum.make$(this, ordinal, name);
}

fan.sys.Weekday.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.Enum.doFromStr(fan.sys.Weekday.$type, name, checked);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Weekday.prototype.increment = function()
{
  var arr = fan.sys.Weekday.m_vals;
  return arr.get((this.m_ordinal+1) % arr.size());
}

fan.sys.Weekday.prototype.decrement = function()
{
  var arr = fan.sys.Weekday.m_vals;
  return this.m_ordinal == 0 ? arr.get(arr.size()-1) : arr.get(this.m_ordinal-1);
}

fan.sys.Weekday.prototype.$typeof = function()
{
  return fan.sys.Weekday.$type;
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

// TODO FIXIT
fan.sys.Weekday.localeStartOfWeek = function()
{
  return fan.sys.Weekday.m_sun;
}

