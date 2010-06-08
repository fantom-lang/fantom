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
fan.sys.TimeZone = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.TimeZone.prototype.$ctor = function()
{
  this.m_name = null;
  this.m_fullName = null;
  this.m_rules = null;
}

fan.sys.TimeZone.listNames = function()
{
  return fan.sys.List.make(fan.sys.Str.$type, fan.sys.TimeZone.names).ro();
}

fan.sys.TimeZone.listFullNames = function()
{
  return fan.sys.List.make(fan.sys.Str.$type, fan.sys.TimeZone.fullNames).ro();
}

fan.sys.TimeZone.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;

  // check cache first
  var tz = fan.sys.TimeZone.cache[name];
  if (tz != null) return tz;

  // TODO - load from server?

  // not found
  if (checked) throw fan.sys.ParseErr.make("TimeZone not found: " + name);
  return null;
}

fan.sys.TimeZone.defVal = function()
{
  return fan.sys.TimeZone.m_utc;
}

fan.sys.TimeZone.utc = function()
{
  return fan.sys.TimeZone.m_utc;
}

fan.sys.TimeZone.rel = function()
{
  return fan.sys.TimeZone.m_rel;
}

fan.sys.TimeZone.cur = function()
{
  // TODO
  if (fan.sys.TimeZone.m_cur == null)
    fan.sys.TimeZone.m_cur = fan.sys.TimeZone.fromStr("New_York");
  return fan.sys.TimeZone.m_cur;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.TimeZone.prototype.toStr = function () { return this.m_name; }

fan.sys.TimeZone.prototype.$typeof = function() { return fan.sys.TimeZone.$type; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.TimeZone.prototype.name = function () { return this.m_name; }

fan.sys.TimeZone.prototype.fullName = function() { return this.m_fullName; }

fan.sys.TimeZone.prototype.offset = function(year)
{
  return fan.sys.Duration.make(this.rule(year).offset * fan.sys.Duration.nsPerSec);
}

fan.sys.TimeZone.prototype.dstOffset = function(year)
{
  var r = this.rule(year);
  if (r.dstOffset == 0) return null;
  return fan.sys.Duration.make(r.dstOffset * fan.sys.Duration.nsPerSec);
}

fan.sys.TimeZone.prototype.stdAbbr = function(year)
{
  return this.rule(year).stdAbbr;
}

fan.sys.TimeZone.prototype.dstAbbr = function(year)
{
  return this.rule(year).dstAbbr;
}

fan.sys.TimeZone.prototype.abbr = function(year, inDST)
{
  return inDST ? this.rule(year).dstAbbr : this.rule(year).stdAbbr;
}

fan.sys.TimeZone.prototype.rule = function(year)
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
fan.sys.TimeZone.dstOffset = function(rule, year, mon, day, time)
{
  var start = rule.dstStart;
  var end   = rule.dstEnd;

  if (start == null) return 0;

  var s = fan.sys.TimeZone.compare(rule, start, year, mon, day, time);
  var e = fan.sys.TimeZone.compare(rule, end,   year, mon, day, time);

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
fan.sys.TimeZone.compare = function(rule, x, year, mon, day, time)
{
  var c = fan.sys.TimeZone.compareMonth(x, mon);
  if (c != 0) return c;

  c = fan.sys.TimeZone.compareOnDay(rule, x, year, mon, day);
  if (c != 0) return c;

  return fan.sys.TimeZone.compareAtTime(rule, x, time);
}

/**
 * Compare month
 */
fan.sys.TimeZone.compareMonth = function(x, mon)
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
fan.sys.TimeZone.compareOnDay = function(rule, x, year, mon, day)
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
      var last = fan.sys.DateTime.weekdayInMonth(year, fan.sys.Month.m_vals.get(mon), fan.sys.Weekday.m_vals.get(x.onWeekday), -1);
      if (last < day) return -1;
      if (last > day) return +1;
      return 0;

    case '>':
      var start = fan.sys.DateTime.weekdayInMonth(year, fan.sys.Month.m_vals.get(mon), fan.sys.Weekday.m_vals.get(x.onWeekday), 1);
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
fan.sys.TimeZone.compareAtTime = function(rule, x, time)
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

fan.sys.TimeZone.cache = [];
fan.sys.TimeZone.names = [];
fan.sys.TimeZone.fullNames = [];
fan.sys.TimeZone.m_utc = null;  // lazy-loaded
fan.sys.TimeZone.m_cur = null;  // lazy-loaded


/*************************************************************************
 * Rule
 ************************************************************************/

fan.sys.TimeZone$Rule = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.TimeZone$Rule.prototype.$ctor = function()
{
  this.startYear = null;  // year rule took effect
  this.offset = null;     // UTC offset in seconds
  this.stdAbbr = null;    // standard time abbreviation
  this.dstOffset = null;  // seconds
  this.dstAbbr = null;    // daylight time abbreviation
  this.dstStart = null;   // starting time
  this.dstEnd = null;     // end time
}
fan.sys.TimeZone$Rule.prototype.isWallTime = function()
{
  return this.dstStart.atMode == 'w';
}

/*************************************************************************
 * DstTime
 ************************************************************************/

fan.sys.TimeZone$DstTime = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.TimeZone$DstTime.prototype.$ctor = function(mon, onMode, onWeekday, onDay, atTime, atMode)
{
  this.mon = mon;              // month (0-11)
  this.onMode = String.fromCharCode(onMode);  // 'd', 'l', '>', '<' (date, last, >=, and <=)
  this.onWeekday = onWeekday;  // weekday (0-6)
  this.onDay = onDay;          // weekday (0-6)
  this.atTime = atTime;        // seconds
  this.atMode = String.fromCharCode(atMode); // 'w' , 's', 'u' (wall, standard, universal)
}

