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
var sys_Date = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Date.prototype.$ctor = function(year, month, day)
{
  this.m_year = year;
  this.m_month = month;
  this.m_day = day;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Date.prototype.equals = function(that)
{
  if (that instanceof sys_Date)
  {
    return this.m_year == that.m_year &&
           this.m_month == that.m_month &&
           this.m_day == that.m_day;
  }
  return false;
}

sys_Date.prototype.compare = function(that)
{
  if (this.m_year == that.m_year)
  {
    if (this.m_month == that.m_month)
    {
      if (this.m_day == that.m_day) return 0;
      return this.m_day < that.m_day ? -1 : +1;
    }
    return this.m_month < that.m_month ? -1 : +1;
  }
  return this.m_year < that.m_year ? -1 : +1;
}

sys_Date.prototype.type = function()
{
  return sys_Type.find("sys::Date");
}

sys_Date.prototype.toIso = function()
{
  return this.toStr();
}

sys_Date.prototype.toLocale = function(pattern)
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

sys_Date.prototype.toStr = function()
{
  // TODO
  var y = this.m_year;
  var m = this.m_month+1;
  var d = this.m_day;
  return y + "-" + (m < 10 ? "0"+m : m) + "-" + (d < 10 ? "0"+d : d);
}

sys_Date.prototype.year  = function() { return this.m_year; }
sys_Date.prototype.month = function() { return sys_Month.values[this.m_month]; }
sys_Date.prototype.day   = function() { return this.m_day; }

sys_Date.prototype.dayOfYear = function()
{
  return sys_DateTime.dayOfYear(this.year(), this.m_month, this.day()+1);
}

sys_Date.prototype.plus = function(d)
{
  var ticks = d.m_ticks;

  // check even number of days
  if (ticks % sys_Duration.nsPerDay != 0)
    throw new sys_ArgErr("Duration must be even num of days");

  var year = this.m_year;
  var month = this.m_month;
  var day = this.m_day;

  var numDays = Math.floor(ticks / sys_Duration.nsPerDay);
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

  return new sys_Date(year, month, day);
}

sys_Date.prototype.minus = function(that)
{
  // short circuit if equal
  if (this.equals(that)) return sys_Duration.defVal;

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
    days = (sys_DateTime.isLeapYear(a.m_year) ? 366 : 365) - a.dayOfYear();
    days += b.dayOfYear();
    for (var i=a.m_year+1; i<b.m_year; ++i)
      days += sys_DateTime.isLeapYear(i) ? 366 : 365;
  }

  // negate if necessary if a was this
  if (a == this) days = -days;

  // map days into ns ticks
  return sys_Duration.make(days * sys_Duration.nsPerDay);
}

sys_Date.prototype.numDays = function(year, mon)
{
  if (sys_DateTime.isLeapYear(year))
    return sys_DateTime.daysInMonLeap[mon];
  else
    return sys_DateTime.daysInMon[mon];
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Date.make = function(year, month, day)
{
  return new sys_Date(year, month.m_ordinal, day);
}

sys_Date.today = function()
{
  var d = new Date();
  return new sys_Date(d.getFullYear(), d.getMonth(), d.getDate());
}

sys_Date.fromStr = function(s, checked)
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

    return new sys_Date(year, month, day);
  }
  catch (err)
  {
    if (checked != null && !checked) return null;
    throw new sys_ParseErr("Date", s);
  }
}

sys_Date.fromIso = function(s, checked)
{
  return sys_Date.fromStr(s, checked);
}