//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Jul 09  Andy Frank  Creation
//

/**
 * TimeZone
 */
var sys_TimeZone = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_TimeZone.prototype.$ctor = function()
{
  this.m_name = null;
  this.m_fullName = null;
  this.m_rules = null;
}

sys_TimeZone.listNames = function()
{
  return sys_List.ro(sys_TimeZone.names);
}

sys_TimeZone.listFullNames = function()
{
  return sys_List.ro(sys_TimeZone.fullNames);
}

sys_TimeZone.fromStr = function(name, checked)
{
  if (checked == undefined) checked = true;

  // check cache first
  var tz = sys_TimeZone.cache[name];
  if (tz != null) return tz;

  // TODO - load from server?

  // not found
  if (checked) throw sys_ParseErr.make("TimeZone not found: " + name);
  return null;
}

sys_TimeZone.defVal = function()
{
  return sys_TimeZone.utc();
}

sys_TimeZone.utc = function()
{
  if (sys_TimeZone.m_utc == null)
    sys_TimeZone.m_utc = sys_TimeZone.fromStr("UTC");
  return sys_TimeZone.m_utc;
}

sys_TimeZone.current = function()
{
  // TODO
  return sys_TimeZone.utc();
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

sys_TimeZone.prototype.toStr = function () { return this.m_name; }

sys_TimeZone.prototype.type = function() { return sys_Type.find("sys::TimeZone"); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_TimeZone.prototype.name = function () { return this.m_name; }

sys_TimeZone.prototype.fullName = function() { return this.m_fullName; }

sys_TimeZone.prototype.offset = function(year)
{
  return sys_Duration.make(this.rule(year).offset * sys_Duration.nsPerSec);
}

sys_TimeZone.prototype.dstOffset = function(year)
{
  var r = this.rule(year);
  if (r.dstOffset == 0) return null;
  return sys_Duration.make(r.dstOffset * sys_Duration.nsPerSec);
}

sys_TimeZone.prototype.stdAbbr = function(year)
{
  return this.rule(year).stdAbbr;
}

sys_TimeZone.prototype.dstAbbr = function(year)
{
  return this.rule(year).dstAbbr;
}

sys_TimeZone.prototype.abbr = function(year, inDST)
{
  return inDST ? this.rule(year).dstAbbr : this.rule(year).stdAbbr;
}

sys_TimeZone.prototype.rule = function(year)
{
  // most hits should be in latest rule
  var rule = this.m_rules[0];
  if (year >= rule.startYear) return rule;

  // check historical time zones
  for (var i=1; i<this.m_rules.length; ++i)
    if (year >= (rule = this.m_rules[i]).startYear) return rule;

  // return oldest rule
  return this.m_rules[this.m_rules.length-1];
}

//////////////////////////////////////////////////////////////////////////
// DST Calculations
//////////////////////////////////////////////////////////////////////////

/**
 * Compute the daylight savings time offset (in seconds)
 * for the specified parameters:
 *  - Rule:    the rule for a given year
 *  - mon:     month 0-11
 *  - day:     day 1-31
 *  - weekday: 0-6
 *  - time:    seconds since midnight
 */
sys_TimeZone.dstOffset = function(rule, year, mon, day, time)
{
  var start = rule.dstStart;
  var end   = rule.dstEnd;

  if (start == null) return 0;

  var s = sys_TimeZone.compare(rule, start, year, mon, day, time);
  var e = sys_TimeZone.compare(rule, end,   year, mon, day, time);

  // if end month comes earlier than start month,
  // then this is dst in southern hemisphere
  if (end.mon < start.mon)
  {
    if (e > 0 || s <= 0) return rule.dstOffset;
  }
  else
  {
    if (s <= 0 && e > 0) return rule.dstOffset;
  }

  return 0;
}

/**
 * Compare the specified time to the dst start/end time.
 * Return -1 if x < specified time and +1 if x > specified time.
 */
sys_TimeZone.compare = function(rule, x, year, mon, day, time)
{
  var c = sys_TimeZone.compareMonth(x, mon);
  if (c != 0) return c;

  c = sys_TimeZone.compareOnDay(rule, x, year, mon, day);
  if (c != 0) return c;

  return sys_TimeZone.compareAtTime(rule, x, time);
}

/**
 * Compare month
 */
sys_TimeZone.compareMonth = function(x, mon)
{
  if (x.mon < mon) return -1;
  if (x.mon > mon) return +1;
  return 0;
}

/**
 * Compare on day.
 *     'd'  5        the fifth of the month
 *     'l'  lastSun  the last Sunday in the month
 *     'l'  lastMon  the last Monday in the month
 *     '>'  Sun>=8   first Sunday on or after the eighth
 *     '<'  Sun<=25  last Sunday on or before the 25th (not used)
 */
sys_TimeZone.compareOnDay = function(rule, x, year, mon, day)
{
  // universal atTime might push us into the previous day
  if (x.atMode == 'u' && rule.offset + x.atTime < 0)
    ++day;

  switch (x.onMode)
  {
    case 'd':
      if (x.onDay < day) return -1;
      if (x.onDay > day) return +1;
      return 0;

    case 'l':
      var last = sys_DateTime.weekdayInMonth(year, sys_Month.values[mon], sys_Weekday.values[x.onWeekday], -1);
      if (last < day) return -1;
      if (last > day) return +1;
      return 0;

    case '>':
      var start = sys_DateTime.weekdayInMonth(year, sys_Month.values[mon], sys_Weekday.values[x.onWeekday], 1);
      while (start < x.onDay) start += 7;
      if (start < day) return -1;
      if (start > day) return +1;
      return 0;

    default:
      throw new Error('' + x.onMode);
  }
}

/**
 * Compare at time.
 */
sys_TimeZone.compareAtTime = function(rule, x, time)
{
  var atTime = x.atTime;

  // if universal time, then we need to move atTime back to
  // local time (we might cross into the previous day)
  if (x.atMode == 'u')
  {
    if (rule.offset + x.atTime < 0)
      atTime = 24*60*60 + rule.offset + x.atTime;
    else
      atTime += rule.offset;
  }

  if (atTime < time) return -1;
  if (atTime > time) return +1;
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

sys_TimeZone.cache = [];
sys_TimeZone.names = [];
sys_TimeZone.fullNames = [];
sys_TimeZone.m_utc = null;      // lazy-loaded
sys_TimeZone.m_current = null;  // lazy-loaded


/*************************************************************************
 * Rule
 ************************************************************************/

var sys_TimeZone$Rule = sys_Obj.$extend(sys_Obj);
sys_TimeZone$Rule.prototype.$ctor = function()
{
  this.startYear = null;  // year rule took effect
  this.offset = null;     // UTC offset in seconds
  this.stdAbbr = null;    // standard time abbreviation
  this.dstOffset = null;  // seconds
  this.dstAbbr = null;    // daylight time abbreviation
  this.dstStart = null;   // starting time
  this.dstEnd = null;     // end time
}
sys_TimeZone$Rule.prototype.isWallTime = function()
{
  return this.dstStart.atMode == 'w';
}

/*************************************************************************
 * DstTime
 ************************************************************************/

var sys_TimeZone$DstTime = sys_Obj.$extend(sys_Obj);
sys_TimeZone$DstTime.prototype.$ctor = function(mon, onMode, onWeekday, onDay, atTime, atMode)
{
  this.mon = mon;              // month (0-11)
  this.onMode = String.fromCharCode(onMode);  // 'd', 'l', '>', '<' (date, last, >=, and <=)
  this.onWeekday = onWeekday;  // weekday (0-6)
  this.onDay = onDay;          // weekday (0-6)
  this.atTime = atTime;        // seconds
  this.atMode = String.fromCharCode(atMode); // 'w' , 's', 'u' (wall, standard, universal)
}

