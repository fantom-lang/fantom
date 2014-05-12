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
  fan.sys.Enum.make$(this, ordinal, name);
  this.m_localeAbbrKey = name + "Abbr";
  this.m_localeFullKey = name + "Full";
}

fan.sys.Month.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.Enum.doFromStr(fan.sys.Month.$type, name, checked);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Month.prototype.increment = function()
{
  var arr = fan.sys.Month.m_vals;
  return arr.get((this.m_ordinal+1) % arr.size());
}

fan.sys.Month.prototype.decrement = function()
{
  var arr = fan.sys.Month.m_vals;
  return this.m_ordinal == 0 ? arr.get(arr.size()-1) : arr.get(this.m_ordinal-1);
}

fan.sys.Month.prototype.numDays = function(year)
{
  if (fan.sys.DateTime.isLeapYear(year))
    return fan.sys.DateTime.daysInMonLeap[this.m_ordinal];
  else
    return fan.sys.DateTime.daysInMon[this.m_ordinal];
}

fan.sys.Month.prototype.$typeof = function()
{
  return fan.sys.Month.$type;
}

fan.sys.Month.prototype.toLocale = function(pattern, locale)
{
  if (locale === undefined || locale == null) locale = fan.sys.Locale.cur();
  if (pattern === undefined) pattern = null;
  if (pattern == null) return this.abbr(locale);
  if (fan.sys.Str.isEveryChar(pattern, 77)) // 'M'
  {
    switch (pattern.length)
    {
      case 1: return ""+(this.m_ordinal+1);
      case 2: return this.m_ordinal < 9 ? "0" + (this.m_ordinal+1) : ""+(this.m_ordinal+1);
      case 3: return this.abbr(locale);
      case 4: return this.full(locale);
    }
  }
  throw fan.sys.ArgErr.make("Invalid pattern: " + pattern);
}

fan.sys.Month.prototype.localeAbbr = function() { return this.abbr(fan.sys.Locale.cur()); }
fan.sys.Month.prototype.abbr = function(locale)
{
  var pod = fan.sys.Pod.find("sys");
  return fan.sys.Env.cur().locale(pod, this.m_localeAbbrKey, this.$name(), locale);
}

fan.sys.Month.prototype.localeFull = function() { return this.full(fan.sys.Locale.cur()); }
fan.sys.Month.prototype.full = function(locale)
{
  var pod = fan.sys.Pod.find("sys");
  return fan.sys.Env.cur().locale(pod, this.m_localeFullKey, this.$name(), locale);
}