//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Date
 */
fan.sys.Date = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Date.prototype.$ctor = function(year, month, day)
{
  this.m_year = year;
  this.m_month = month;
  this.m_day = day;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Date.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Date)
  {
    return this.m_year.valueOf() == that.m_year.valueOf() &&
           this.m_month.valueOf() == that.m_month.valueOf() &&
           this.m_day.valueOf() == that.m_day.valueOf();
  }
  return false;
}

fan.sys.Date.prototype.compare = function(that)
{
  if (this.m_year.valueOf() == that.m_year.valueOf())
  {
    if (this.m_month.valueOf() == that.m_month.valueOf())
    {
      if (this.m_day.valueOf() == that.m_day.valueOf()) return 0;
      return this.m_day < that.m_day ? -1 : +1;
    }
    return this.m_month < that.m_month ? -1 : +1;
  }
  return this.m_year < that.m_year ? -1 : +1;
}

fan.sys.Date.prototype.$typeof = function()
{
  return fan.sys.Date.$type;
}

fan.sys.Date.prototype.toIso = function()
{
  return this.toStr();
}

fan.sys.Date.prototype.toLocale = function(pattern)
{
  // TODO
  var s = "" + this.m_day + "-";
  switch (this.m_month)
  {
    case 0:  s += "Jan"; break;
    case 1:  s += "Feb"; break;
    case 2:  s += "Mar"; break;
    case 3:  s += "Apr"; break;
    case 4:  s += "May"; break;
    case 5:  s += "Jun"; break;
    case 6:  s += "Jul"; break;
    case 7:  s += "Aug"; break;
    case 8:  s += "Sep"; break;
    case 9:  s += "Oct"; break;
    case 10: s += "Nov"; break;
    case 11: s += "Dec"; break;
  }
  s += "-" + this.m_year;
  return s;
}

fan.sys.Date.prototype.toStr = function()
{
  // TODO
  var y = this.m_year;
  var m = this.m_month+1;
  var d = this.m_day;
  return y + "-" + (m < 10 ? "0"+m : m) + "-" + (d < 10 ? "0"+d : d);
}

fan.sys.Date.prototype.year  = function() { return this.m_year; }
fan.sys.Date.prototype.month = function() { return fan.sys.Month.m_vals.get(this.m_month); }
fan.sys.Date.prototype.day   = function() { return this.m_day; }

fan.sys.Date.prototype.weekday = function()
{
  var weekday = (fan.sys.DateTime.firstWeekday(this.m_year, this.m_month) + this.m_day - 1) % 7;
  return fan.sys.Weekday.m_vals.get(weekday);
}

fan.sys.Date.prototype.dayOfYear = function()
{
  return fan.sys.DateTime.dayOfYear(this.year(), this.m_month, this.day()+1);
}

fan.sys.Date.prototype.plus = function(d)
{
  var ticks = d.m_ticks;

  // check even number of days
  if (ticks % fan.sys.Duration.nsPerDay != 0)
    throw fan.sys.ArgErr.make("Duration must be even num of days");

  var year = this.m_year;
  var month = this.m_month;
  var day = this.m_day;

  var numDays = fan.sys.Int.div(ticks, fan.sys.Duration.nsPerDay);
  var dayIncr = numDays < 0 ? +1 : -1;
  while (numDays != 0)
  {
    if (numDays > 0)
    {
      day++;
      if (day > this.numDays(year, month))
      {
        day = 1;
        month++;
        if (month >= 12) { month = 0; year++; }
      }
      numDays--;
    }
    else
    {
      day--;
      if (day <= 0)
      {
        month--;
        if (month < 0) { month = 11; year--; }
        day = this.numDays(year, month);
      }
      numDays++;
    }
  }

  return new fan.sys.Date(year, month, day);
}

fan.sys.Date.prototype.minus = function(d)
{
  return this.plus(d.negate());
}

fan.sys.Date.prototype.minusDate = function(that)
{
  // short circuit if equal
  if (this.equals(that)) return fan.sys.Duration.m_defVal;

  // compute so that a < b
  var a = this;
  var b = that;
  if (a.compare(b) > 0) { b = this; a = that; }

  // compute difference in days
  var days = 0;
  if (a.m_year == b.m_year)
  {
    days = b.dayOfYear() - a.dayOfYear();
  }
  else
  {
    days = (fan.sys.DateTime.isLeapYear(a.m_year) ? 366 : 365) - a.dayOfYear();
    days += b.dayOfYear();
    for (var i=a.m_year+1; i<b.m_year; ++i)
      days += fan.sys.DateTime.isLeapYear(i) ? 366 : 365;
  }

  // negate if necessary if a was this
  if (a == this) days = -days;

  // map days into ns ticks
  return fan.sys.Duration.make(days * fan.sys.Duration.nsPerDay);
}

fan.sys.Date.prototype.numDays = function(year, mon)
{
  if (fan.sys.DateTime.isLeapYear(year))
    return fan.sys.DateTime.daysInMonLeap[mon];
  else
    return fan.sys.DateTime.daysInMon[mon];
}

fan.sys.Date.prototype.firstOfMonth = function()
{
  if (this.m_day == 1) return this;
  return new fan.sys.Date(this.m_year, this.m_month, 1);
}

fan.sys.Date.prototype.lastOfMonth = function()
{
  var last = this.month().numDays(this.m_year);
  if (this.m_day == last) return this;
  return new fan.sys.Date(this.m_year, this.m_month, last);
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Date.make = function(year, month, day)
{
  return new fan.sys.Date(year, month.m_ordinal, day);
}

fan.sys.Date.today = function()
{
  var d = new Date();
  return new fan.sys.Date(d.getFullYear(), d.getMonth(), d.getDate());
}

fan.sys.Date.fromStr = function(s, checked)
{
  try
  {
    var num = function(x, index) { return x.charCodeAt(index) - 48; }

    // YYYY-MM-DD
    var year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
    var month = num(s, 5)*10   + num(s, 6) - 1;
    var day   = num(s, 8)*10   + num(s, 9);

    // check separator symbols and length
    if (s.charAt(4) != '-' || s.charAt(7) != '-' || s.length != 10)
      throw new Error();

    return new fan.sys.Date(year, month, day);
  }
  catch (err)
  {
    if (checked != null && !checked) return null;
    throw fan.sys.ParseErr.make("Date", s);
  }
}

fan.sys.Date.fromIso = function(s, checked)
{
  return fan.sys.Date.fromStr(s, checked);
}

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

fan.sys.Date.prototype.isYesterday = function() { return this.equals(fan.sys.Date.today().plus(fan.sys.Duration.m_negOneDay)); }
fan.sys.Date.prototype.isToday     = function() { return this.equals(fan.sys.Date.today()); }
fan.sys.Date.prototype.isTomorrow  = function() { return this.equals(fan.sys.Date.today().plus(fan.sys.Duration.m_oneDay)); }

fan.sys.Date.prototype.toDateTime = function(t, tz)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();
  return fan.sys.DateTime.makeDT(this, t, tz);
}

fan.sys.Date.prototype.midnight = function(tz)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();
  return fan.sys.DateTime.makeDT(this, fan.sys.Time.m_defVal, tz);
}

fan.sys.Date.prototype.toCode = function()
{
  if (this.equals(fan.sys.Date.m_defVal)) return "Date.defVal";
  return "Date(\"" + this.toString() + "\")";
}

