//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * DateTime
 */
var sys_DateTime = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor - Values
//////////////////////////////////////////////////////////////////////////

sys_DateTime.prototype.$ctor = function() {}

sys_DateTime.make = function(year, month, day, hour, min, sec, ns, tz)
{
  if (sec == undefined) sec = 0;
  if (ns  == undefined) ns = 0;
  //if (tz  == undefined) tz = TimeZone.current;

  month = month.ordinal();

  if (year < 1901 || year > 2099) throw sys_ArgErr.make("year " + year);
  if (month < 0 || month > 11)    throw sys_ArgErr.make("month " + month);
  if (day < 1 || day > sys_DateTime.numDaysInMonth(year, month)) throw sys_ArgErr.make("day " + day);
  if (hour < 0 || hour > 23)      throw sys_ArgErr.make("hour " + hour);
  if (min < 0 || min > 59)        throw sys_ArgErr.make("min " + min);
  if (sec < 0 || sec > 59)        throw sys_ArgErr.make("sec " + sec);
  if (ns < 0 || ns > 999999999)  throw sys_ArgErr.make("ns " + ns);

  // compute ticks for UTC
  var dayOfYear = sys_DateTime.dayOfYear(year, month, day);
  var timeInSec = hour*3600 + min*60 + sec;
  var ticks = sys_Int.plus(sys_DateTime.yearTicks[year-1900],
              sys_Int.plus(dayOfYear * nsPerDay,
              sys_Int.plus(timeInSec * nsPerSec, ns)));

  // adjust for timezone and dst (we might know the UTC offset)
  /*
  TimeZone.Rule rule = tz.rule(year);
  boolean dst;
  if (sys_Int.equal(knownOffset, sys_Int.maxVal))
  {
    // don't know offset so compute from timezone rule
    ticks -= rule.offset * sys_DateTime.nsPerSec;
    int dstOffset = TimeZone.dstOffset(rule, year, month, day, timeInSec);
    if (dstOffset != 0) ticks -= (long)dstOffset * nsPerSec;
    dst = dstOffset != 0;
  }
  else
  {
    // we known offset, still need to use rule to compute if in dst
    ticks -= (long)knownOffset * nsPerSec;
    dst = knownOffset != rule.offset;
  }
  */

  // compute weekday
  var weekday = (sys_DateTime.firstWeekday(year, month) + day - 1) % 7;

  // fields
  var fields = 0;
  fields |= ((year-1900) & 0xff) << 0;
  fields |= (month & 0xf) << 8;
  fields |= (day & 0x1f)  << 12;
  fields |= (hour & 0x1f) << 17;
  fields |= (min  & 0x3f) << 22;
  fields |= (weekday & 0x7) << 28;
//  fields |= (dst ? 1 : 0) << 31;

  // commit
  var instance = new sys_DateTime();
  instance.ticks    = ticks;
  instance.timeZone = tz;
  instance.fields   = fields;
  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Constructor - Ticks
//////////////////////////////////////////////////////////////////////////

sys_DateTime.makeTicks = function(ticks, tz)
{
  // if (tz == undefined) tz = TimeZone.current

  // check boundary conditions 1901 to 2099
  if (ticks < sys_DateTime.minTicks || ticks >= sys_DateTime.maxTicks)
    throw sys_ArgErr.make("Ticks out of range 1901 to 2099");

  // save ticks, time zone
  var instance = new sys_DateTime();
  instance.ticks = ticks;
  instance.timeZone = tz;

  // compute the year
  var year = sys_DateTime.ticksToYear(ticks);

  // get the time zone rule for this year, and
  // offset the working ticks by UTC offset
//  TimeZone.Rule rule = timeZone.rule(year);
//  ticks += rule.offset * nsPerSec;

  // compute the day and month; we may need to execute this
  // code block up to three times:
  //   1st: using standard time
  //   2nd: using daylight offset (if in dst)
  //   3rd: using standard time (if dst pushed us back into std)
  var month, day, dstOffset = 0;
  var rem;
  while (true)
  {
    // recompute year based on working ticks
    year = sys_DateTime.ticksToYear(ticks);
    rem = ticks - sys_DateTime.yearTicks[year-1900];
    if (rem < 0) rem += sys_DateTime.nsPerYear;

    // compute day of the year
    var dayOfYear = Math.floor(rem/sys_DateTime.nsPerDay);
    rem %= sys_DateTime.nsPerDay;

    // use lookup tables map day of year to month and day
    if (sys_DateTime.isLeapYear(year))
    {
      month = sys_DateTime.monForDayOfYearLeap[dayOfYear];
      day   = sys_DateTime.dayForDayOfYearLeap[dayOfYear];
    }
    else
    {
      month = sys_DateTime.monForDayOfYear[dayOfYear];
      day   = sys_DateTime.dayForDayOfYear[dayOfYear];
    }

    // if dstOffset is set to max, then this is
    // the third time thru the loop: std->dst->std
    if (sys_Int.equals(dstOffset, sys_Int.maxVal)) { dstOffset = 0; break; }

    // if dstOffset is non-zero we have run this
    // loop twice to recompute the date for dst
    /*
    if (dstOffset != 0)
    {
      // if our dst rule is wall time based, then we need to
      // recompute to see if dst wall time pushed us back
      // into dst - if so then run through the loop a third
      // time to get us back to standard time
      if (rule.isWallTime() && TimeZone.dstOffset(rule, year, month, day, Math.floor(rem/nsPerSec)) == 0)
      {
        ticks -= dstOffset * nsPerSec;
        dstOffset = Integer.MAX_VALUE;
        continue;
      }
      break;
    }
    */

    // first time in loop; check for daylight saving time,
    // and if dst is in effect then re-run this loop with
    // modified working ticks
//    dstOffset = TimeZone.dstOffset(rule, year, month, day, Math.floor(rem/nsPerSec));
    if (dstOffset == 0) break;
//    ticks += dstOffset * sys_DateTime.nsPerSec;
  }

  // compute time of day
  var hour = Math.floor(rem / sys_DateTime.nsPerHour);  rem %= sys_DateTime.nsPerHour;
  var min  = Math.floor(rem / sys_DateTime.nsPerMin);   rem %= sys_DateTime.nsPerMin;

  // compute weekday
  var weekday = (sys_DateTime.firstWeekday(year, month) + day - 1) % 7;

  // fields
  var fields = 0;
  fields |= ((year-1900) & 0xff) << 0;
  fields |= (month & 0xf) << 8;
  fields |= (day & 0x1f)  << 12;
  fields |= (hour & 0x1f) << 17;
  fields |= (min  & 0x3f) << 22;
  fields |= (weekday & 0x7) << 28;
  fields |= (dstOffset != 0 ? 1 : 0) << 31;
  instance.fields = fields;

  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Constructor - FromStr
//////////////////////////////////////////////////////////////////////////

sys_DateTime.fromStr = function(s, checked, iso)
{
  if (checked == undefined) checked = true;
  if (iso == undefined) iso = false;

  try
  {
    var num = function(s, index) { return s.charCodeAt(index) - 48; }

    // YYYY-MM-DD'T'hh:mm:ss
    var year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
    var month = num(s, 5)*10   + num(s, 6) - 1;
    var day   = num(s, 8)*10   + num(s, 9);
    var hour  = num(s, 11)*10  + num(s, 12);
    var min   = num(s, 14)*10  + num(s, 15);
    var sec   = num(s, 17)*10  + num(s, 18);

    // check separator symbols
    if (s.charAt(4)  != '-' || s.charAt(7)  != '-' ||
        s.charAt(10) != 'T' || s.charAt(13) != ':' ||
        s.charAt(16) != ':')
      throw new Error();

    // optional .FFFFFFFFF
    var i = 19;
    var ns = 0;
    var tenth = 100000000;
    if (s.charAt(i) == '.')
    {
      ++i;
      while (true)
      {
        var c = s.charCodeAt(i);
        if (c < 48 || c > 57) break;
        ns += (c - 48) * tenth;
        tenth /= 10;
        ++i;
      }
    }

    // zone offset
    var offset = 0;
    var c = s.charAt(i++);
    if (c != 'Z')
    {
      var offHour = num(s, i++)*10 + num(s, i++);
      if (s.charAt(i++) != ':') throw new Exception();
      var offMin  = num(s, i++)*10 + num(s, i++);
      offset = offHour*3600 + offMin*60;
      if (c == '-') offset = -offset;
      else if (c != '+') throw new Error();
    }

    // timezone - we share this method b/w fromStr and fromIso
    var tz;
    if (iso)
    {
      if (i < s.length()) throw new Error();
      if (offset == 0)
        tz = TimeZone.utc();
      else
        tz = TimeZone.fromStr("GMT" + (offset < 0 ? "+" : "-") + Math.abs(offset)/3600);
    }
    else
    {
      if (s.charAt(i++) != ' ') throw new Error();
      tz = TimeZone.fromStr(s.substring(i), true);
    }

    return sys_DateTime.make(year, month, day, hour, min, sec, ns, offset, tz);
  }
  catch (err)
  {
    if (!checked) return null;
    throw sys_ParseErr.make("DateTime", s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_DateTime.prototype.equals = function(obj)
{
  if (obj instanceof sys_DateTime)
  {
    return this.ticks == obj.ticks;
  }
  return false;
}

sys_DateTime.prototype.hash = function()
{
  return this.ticks;
}

sys_DateTime.prototype.compare = function(obj)
{
  var that = obj.ticks;
  if (this.ticks < that) return -1; return this.ticks  == that ? 0 : +1;
}

sys_DateTime.prototype.type = function()
{
  return sys_Type.find("sys::DateTime");
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_DateTime.isLeapYear = function(year)
{
  if ((year & 3) != 0) return false;
  return (year % 100 != 0) || (year % 400 == 0);
}

sys_DateTime.weekdayInMonth = function(year, mon, weekday, pos)
{
  mon = mon.m_ordinal;
  weekday = weekday.m_ordinal;

  // argument checking
  sys_DateTime.checkYear(year);
  if (pos == 0) throw sys_ArgErr.make("Pos is zero");

  // compute the weekday of the 1st of this month (0-6)
  var firstWeekday = sys_DateTime.firstWeekday(year, mon);

  // get number of days in this month
  var numDays = sys_DateTime.numDaysInMonth(year, mon);

  if (pos > 0)
  {
    var day = weekday - firstWeekday + 1;
    if (day <= 0) day = 8 - firstWeekday + weekday;
    day += (pos-1)*7;
    if (day > numDays) throw sys_ArgErr.make("Pos out of range " + pos);
    return day;
  }
  else
  {
    var lastWeekday = (firstWeekday + numDays - 1) % 7;
    var off = lastWeekday - weekday;
    if (off < 0) off = 7 + off;
    off -= (pos+1)*7;
    var day = numDays - off;
    if (day < 1) throw sys_ArgErr.make("Pos out of range " + pos);
    return day;
  }
}

sys_DateTime.dayOfYear = function(year, mon, day)
{
  return sys_DateTime.isLeapYear(year) ?
    sys_DateTime.dayOfYearForFirstOfMonLeap[mon] + day - 1 :
    sys_DateTime.dayOfYearForFirstOfMon[mon] + day - 1;
}

sys_DateTime.numDaysInMonth = function(year, month)
{
  if (month == 1 && sys_DateTime.isLeapYear(year))
    return 29;
  else
    return sys_DateTime.daysInMon[month];
}

sys_DateTime.ticksToYear = function(ticks)
{
  // estimate the year to get us in the ball park, then
  // match the exact year using the yearTicks lookup table
  var year = Math.floor(ticks/sys_DateTime.nsPerYear) + 2000;
  if (sys_DateTime.yearTicks[year-1900] > ticks) year--;
  return year;
}

sys_DateTime.firstWeekday = function(year, mon)
{
  // get the 1st day of this month as a day of year (0-365)
  var firstDayOfYear = sys_DateTime.isLeapYear(year)
    ? sys_DateTime.dayOfYearForFirstOfMonLeap[mon]
    : sys_DateTime.dayOfYearForFirstOfMon[mon];

  // compute the weekday of the 1st of this month (0-6)
  return (sys_DateTime.firstWeekdayOfYear[year-1900] + firstDayOfYear) % 7;
}

sys_DateTime.checkYear = function(year)
{
  if (year < 1901 || year > 2099)
    throw sys_ArgErr.make("Year out of range " + year);
}

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

// TODO - make sys_Ints
sys_DateTime.nsPerYear  = 365*24*60*60*1000000000;
sys_DateTime.nsPerDay   = 24*60*60*1000000000;
sys_DateTime.nsPerHour  = 60*60*1000000000;
sys_DateTime.nsPerMin   = 60*1000000000;
sys_DateTime.nsPerSec   = 1000000000;
sys_DateTime.nsPerMilli = 1000000;
sys_DateTime.minTicks   = -3124137600000000000; // 1901
sys_DateTime.maxTicks   = 3155760000000000000;  // 2100

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// ns ticks for jan 1 of year 1900-2100
sys_DateTime.yearTicks = [];

// first weekday (0-6) of year indexed by year 1900-2100
sys_DateTime.firstWeekdayOfYear = [];

sys_DateTime.yearTicks[0] = -3155673600000000000; // ns ticks for 1900
sys_DateTime.firstWeekdayOfYear[0] = 1;
for (var i=1; i<202; ++i)
{
  var daysInYear = 365;
  if (sys_DateTime.isLeapYear(i+1900-1)) daysInYear = 366;
  sys_DateTime.yearTicks[i] = sys_DateTime.yearTicks[i-1] + daysInYear * sys_DateTime.nsPerDay;
  sys_DateTime.firstWeekdayOfYear[i] = (sys_DateTime.firstWeekdayOfYear[i-1] + daysInYear) % 7;
}

// number of days in each month indexed by month (0-11)
sys_DateTime.daysInMon     = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
sys_DateTime.daysInMonLeap = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

// day of year (0-365) for 1st day of month (0-11)
sys_DateTime.dayOfYearForFirstOfMon     = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
sys_DateTime.dayOfYearForFirstOfMonLeap = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
for (var i=1; i<12; ++i)
{
  sys_DateTime.dayOfYearForFirstOfMon[i] =
    sys_DateTime.dayOfYearForFirstOfMon[i-1] + sys_DateTime.daysInMon[i-1];

  sys_DateTime.dayOfYearForFirstOfMonLeap[i] =
    sys_DateTime.dayOfYearForFirstOfMonLeap[i-1] + sys_DateTime.daysInMonLeap[i-1];
}

// month and day of month indexed by day of the year (0-365)
sys_DateTime.monForDayOfYear     = [];
sys_DateTime.dayForDayOfYear     = [];
sys_DateTime.monForDayOfYearLeap = [];
sys_DateTime.dayForDayOfYearLeap = [];
sys_DateTime.fillInDayOfYear = function(mon, days, daysInMon, len)
{
  var m = 0, d = 1;
  for (var i=0; i<len; ++i)
  {
    mon[i] = m; days[i] = d++;
    if (d > daysInMon[m]) { m++; d = 1; }
  }
}
sys_DateTime.fillInDayOfYear(sys_DateTime.monForDayOfYear, sys_DateTime.dayForDayOfYear, sys_DateTime.daysInMon, 365);
sys_DateTime.fillInDayOfYear(sys_DateTime.monForDayOfYearLeap, sys_DateTime.dayForDayOfYearLeap, sys_DateTime.daysInMonLeap, 366);

