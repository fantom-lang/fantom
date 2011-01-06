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
  this.m_localeAbbrKey = name + "Abbr";
  this.m_localeFullKey = name + "Full";
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

fan.sys.Weekday.prototype.toLocale = function(pattern)
{
  if (pattern === undefined) pattern = null;
  if (pattern == null) return this.localeAbbr();
  if (fan.sys.Str.isEveryChar(pattern, 87)) // 'W'
  {
    switch (pattern.length)
    {
      case 3: return this.localeAbbr();
      case 4: return this.localeFull();
    }
  }
  throw fan.sys.ArgErr.make("Invalid pattern: " + pattern);
}

fan.sys.Weekday.prototype.localeAbbr = function() { return this.abbr(fan.sys.Locale.cur()); }
fan.sys.Weekday.prototype.abbr = function(locale)
{
  var pod = fan.sys.Pod.find("sys");
  return fan.sys.Env.cur().locale(pod, this.m_localeAbbrKey, this.name(), locale);
}

fan.sys.Weekday.prototype.localeFull = function() { return this.full(fan.sys.Locale.cur()); }
fan.sys.Weekday.prototype.full = function(locale)
{
  var pod = fan.sys.Pod.find("sys");
  return fan.sys.Env.cur().locale(pod, this.m_localeFullKey, this.name(), locale);
}

fan.sys.Weekday.localeStartOfWeek = function()
{
  var pod = fan.sys.Pod.find("sys");
  return fan.sys.Weekday.fromStr(fan.sys.Env.cur().locale(pod, "weekdayStart", "sun"));
}

fan.sys.Weekday.localeVals = function()
{
  var start = fan.sys.Weekday.localeStartOfWeek();
  var list = fan.sys.Weekday.m_localeVals[start.m_ordinal];
  if (list == null)
  {
    list = fan.sys.List.make(fan.sys.Weekday.$type);
    for (var i=0; i<7; ++i)
      list.add(fan.sys.Weekday.m_vals.get((i + start.m_ordinal) % 7));
    fan.sys.Weekday.m_localeVals[start.m_ordinal] = list.toImmutable();
  }
  return list;
}
fan.sys.Weekday.m_localeVals = [];
