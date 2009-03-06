//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//

/**
 * Date
 */
var sys_Date = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(year, month, day)
  {
    this.m_year = year;
    this.m_month = month;
    this.m_day = day;
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  equals: function(that)
  {
    if (that instanceof sys_Date)
    {
      return this.m_year == that.m_year &&
             this.m_month == that.m_month &&
             this.m_day == that.m_day;
    }
    return false;
  },

  compare: function(that)
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
  },

  type: function()
  {
    return sys_Type.find("sys::Date");
  },

  toIso: function()
  {
    return this.toStr();
  },

  toLocale: function(pattern)
  {
    // TODO
    return this.toStr();
  },

  toStr: function()
  {
    // TODO
    var y = this.m_year;
    var m = this.m_month+1;
    var d = this.m_day;
    return y + "-" + (m < 10 ? "0"+m : m) + "-" + (d < 10 ? "0"+d : d);
  },

  year: function() { return this.m_year; },
  month: function() { return sys_Month.values[this.m_month]; },
  day: function() { return this.m_day; },

  plus: function(d) { return this.add(d.m_ticks); },
  minus: function(d) { return this.add(-d.m_ticks); },
  add: function(ticks)
  {
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
  },

  numDays: function(year, mon)
  {
    if (sys_DateTime.isLeapYear(year))
      return sys_DateTime.daysInMonLeap[mon];
    else
      return sys_DateTime.daysInMon[mon];
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_year: 0,
  m_month: 0,
  m_day: 0

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
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