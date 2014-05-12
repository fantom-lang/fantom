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
fan.sys.DateTime = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

// TODO - make fan.sys.Ints
fan.sys.DateTime.diffJs     = 946684800000; // 2000-1970 in milliseconds
fan.sys.DateTime.nsPerYear  = 365*24*60*60*1000000000;
fan.sys.DateTime.nsPerDay   = 24*60*60*1000000000;
fan.sys.DateTime.nsPerHour  = 60*60*1000000000;
fan.sys.DateTime.nsPerMin   = 60*1000000000;
fan.sys.DateTime.nsPerSec   = 1000000000;
fan.sys.DateTime.nsPerMilli = 1000000;
fan.sys.DateTime.minTicks   = -3124137600000000000; // 1901
fan.sys.DateTime.maxTicks   = 3155760000000000000;  // 2100

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.now = function(tolerance)
{
  if (tolerance === undefined)
  {
    if (fan.sys.DateTime.toleranceDefault == null)
      fan.sys.DateTime.toleranceDefault = fan.sys.Duration.makeMillis(250);

    tolerance = fan.sys.DateTime.toleranceDefault;
  }

  var now = fan.sys.DateTime.nowTicks();

  if (fan.sys.DateTime.cached == null)
    fan.sys.DateTime.cached = fan.sys.DateTime.makeTicks(0, fan.sys.TimeZone.cur());

  var c = fan.sys.DateTime.cached;
  if (tolerance != null && now - c.m_ticks <= tolerance.m_ticks)
      return c;

  fan.sys.DateTime.cached = fan.sys.DateTime.makeTicks(now, fan.sys.TimeZone.cur());
  return fan.sys.DateTime.cached;
}

fan.sys.DateTime.nowUtc = function(tolerance)
{
  if (tolerance === undefined)
  {
    if (fan.sys.DateTime.toleranceDefault == null)
      fan.sys.DateTime.toleranceDefault = fan.sys.Duration.makeMillis(250);

    tolerance = fan.sys.DateTime.toleranceDefault;
  }

  var now = fan.sys.DateTime.nowTicks();

  if (fan.sys.DateTime.cachedUtc == null)
    fan.sys.DateTime.cachedUtc = fan.sys.DateTime.makeTicks(0, fan.sys.TimeZone.utc());

  var c = fan.sys.DateTime.cachedUtc;
  if (tolerance != null && now - c.m_ticks <= tolerance.m_ticks)
      return c;

  fan.sys.DateTime.cachedUtc = fan.sys.DateTime.makeTicks(now, fan.sys.TimeZone.utc());
  return fan.sys.DateTime.cachedUtc;
}

fan.sys.DateTime.nowTicks = function()
{
  return (new Date().getTime() - fan.sys.DateTime.diffJs) * fan.sys.DateTime.nsPerMilli
}

fan.sys.DateTime.boot = function()
{
  if (fan.sys.DateTime.m_boot === undefined)
    fan.sys.DateTime.m_boot = fan.sys.DateTime.now();
  return fan.sys.DateTime.m_boot;
}

//////////////////////////////////////////////////////////////////////////
// Constructor - Values
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.$ctor = function() {}

fan.sys.DateTime.make = function(year, month, day, hour, min, sec, ns, tz)
{
  return fan.sys.DateTime.doMake(year, month, day, hour, min, sec, ns, undefined, tz);
}

fan.sys.DateTime.doMake = function(year, month, day, hour, min, sec, ns, knownOffset, tz)
{
  if (sec === undefined) sec = 0;
  if (ns  === undefined) ns = 0;
  if (tz  === undefined) tz = fan.sys.TimeZone.cur();

  month = month.ordinal();

  if (year < 1901 || year > 2099) throw fan.sys.ArgErr.make("year " + year);
  if (month < 0 || month > 11)    throw fan.sys.ArgErr.make("month " + month);
  if (day < 1 || day > fan.sys.DateTime.numDaysInMonth(year, month)) throw fan.sys.ArgErr.make("day " + day);
  if (hour < 0 || hour > 23)      throw fan.sys.ArgErr.make("hour " + hour);
  if (min < 0 || min > 59)        throw fan.sys.ArgErr.make("min " + min);
  if (sec < 0 || sec > 59)        throw fan.sys.ArgErr.make("sec " + sec);
  if (ns < 0 || ns > 999999999)   throw fan.sys.ArgErr.make("ns " + ns);

  // compute ticks for UTC
  var dayOfYear = fan.sys.DateTime.dayOfYear(year, month, day);
  var timeInSec = hour*3600 + min*60 + sec;
  var ticks = fan.sys.Int.plus(fan.sys.DateTime.yearTicks[year-1900],
              fan.sys.Int.plus(dayOfYear * fan.sys.DateTime.nsPerDay,
              fan.sys.Int.plus(timeInSec * fan.sys.DateTime.nsPerSec, ns)));

  // adjust for timezone and dst (we might know the UTC offset)
  var rule = tz.rule(year);
  var dst;
  if (knownOffset == null)
  {
    // don't know offset so compute from timezone rule
    ticks -= rule.offset * fan.sys.DateTime.nsPerSec;
    var dstOffset = fan.sys.TimeZone.dstOffset(rule, year, month, day, timeInSec);
    if (dstOffset != 0) ticks -= dstOffset * fan.sys.DateTime.nsPerSec;
    dst = dstOffset != 0;
  }
  else
  {
    // we known offset, still need to use rule to compute if in dst
    ticks -= knownOffset * fan.sys.DateTime.nsPerSec;
    dst = knownOffset != rule.offset;
  }

  // compute weekday
  var weekday = (fan.sys.DateTime.firstWeekday(year, month) + day - 1) % 7;

  // fields
  var fields = 0;
  fields |= ((year-1900) & 0xff) << 0;
  fields |= (month & 0xf) << 8;
  fields |= (day & 0x1f)  << 12;
  fields |= (hour & 0x1f) << 17;
  fields |= (min  & 0x3f) << 22;
  fields |= (weekday & 0x7) << 28;
  fields |= (dst ? 1 : 0) << 31;

  // commit
  var instance = new fan.sys.DateTime();
  instance.m_ticks = ticks;
  instance.m_ns    = ns;
  instance.m_tz    = tz;
  instance.m_fields   = fields;
  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Constructor - Date,Time
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.makeDT = function(d, t, tz)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();
  return fan.sys.DateTime.make(
    d.year(), d.month(), d.day(),
    t.hour(), t.min(), t.sec(), t.nanoSec(), tz);
}

//////////////////////////////////////////////////////////////////////////
// Constructor - Ticks
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.makeTicks = function(ticks, tz)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();

  // check boundary conditions 1901 to 2099
  if (ticks < fan.sys.DateTime.minTicks || ticks >= fan.sys.DateTime.maxTicks)
    throw fan.sys.ArgErr.make("Ticks out of range 1901 to 2099");

  // save ticks, time zone
  var instance = new fan.sys.DateTime();
  instance.m_ticks = ticks;
  instance.m_tz    = tz;

  // compute the year
  var year = fan.sys.DateTime.ticksToYear(ticks);

  // get the time zone rule for this year, and
  // offset the working ticks by UTC offset
  var rule = tz.rule(year);
  ticks += rule.offset * fan.sys.DateTime.nsPerSec;

  // compute the day and month; we may need to execute this
  // code block up to three times:
  //   1st: using standard time
  //   2nd: using daylight offset (if in dst)
  //   3rd: using standard time (if dst pushed us back into std)
  var month = 0, day = 0, dstOffset = 0;
  var rem;
  while (true)
  {
    // recompute year based on working ticks
    year = fan.sys.DateTime.ticksToYear(ticks);
    rem = ticks - fan.sys.DateTime.yearTicks[year-1900];
    if (rem < 0) rem += fan.sys.DateTime.nsPerYear;

    // compute day of the year
    var dayOfYear = fan.sys.Int.div(rem, fan.sys.DateTime.nsPerDay);
    rem %= fan.sys.DateTime.nsPerDay;

    // use lookup tables map day of year to month and day
    if (fan.sys.DateTime.isLeapYear(year))
    {
      month = fan.sys.DateTime.monForDayOfYearLeap[dayOfYear];
      day   = fan.sys.DateTime.dayForDayOfYearLeap[dayOfYear];
    }
    else
    {
      month = fan.sys.DateTime.monForDayOfYear[dayOfYear];
      day   = fan.sys.DateTime.dayForDayOfYear[dayOfYear];
    }

    // if dstOffset is set to max, then this is
    // the third time thru the loop: std->dst->std
    if (dstOffset == null) { dstOffset = 0; break; }

    // if dstOffset is non-zero we have run this
    // loop twice to recompute the date for dst
    if (dstOffset != 0)
    {
      // if our dst rule is wall time based, then we need to
      // recompute to see if dst wall time pushed us back
      // into dst - if so then run through the loop a third
      // time to get us back to standard time
      if (rule.isWallTime() && fan.sys.TimeZone.dstOffset(rule, year, month, day, fan.sys.Int.div(rem, fan.sys.DateTime.nsPerSec)) == 0)
      {
        ticks -= dstOffset * fan.sys.DateTime.nsPerSec;
        dstOffset = null;
        continue;
      }
      break;
    }

    // first time in loop; check for daylight saving time,
    // and if dst is in effect then re-run this loop with
    // modified working ticks
    dstOffset = fan.sys.TimeZone.dstOffset(rule, year, month, day, fan.sys.Int.div(rem, fan.sys.DateTime.nsPerSec));
    if (dstOffset == 0) break;
    ticks += dstOffset * fan.sys.DateTime.nsPerSec;
  }

  // compute time of day
  var hour = fan.sys.Int.div(rem, fan.sys.DateTime.nsPerHour);  rem %= fan.sys.DateTime.nsPerHour;
  var min  = fan.sys.Int.div(rem, fan.sys.DateTime.nsPerMin);   rem %= fan.sys.DateTime.nsPerMin;

  // compute weekday
  var weekday = (fan.sys.DateTime.firstWeekday(year, month) + day - 1) % 7;

  // compute nanos
  var rem = ticks >= 0 ? ticks : ticks - fan.sys.DateTime.yearTicks[0];
  instance.m_ns = rem % fan.sys.DateTime.nsPerSec;

  // fields
  var fields = 0;
  fields |= ((year-1900) & 0xff) << 0;
  fields |= (month & 0xf) << 8;
  fields |= (day & 0x1f)  << 12;
  fields |= (hour & 0x1f) << 17;
  fields |= (min  & 0x3f) << 22;
  fields |= (weekday & 0x7) << 28;
  fields |= (dstOffset != 0 ? 1 : 0) << 31;
  instance.m_fields = fields;

  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Constructor - FromStr
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.fromStr = function(s, checked, iso)
{
  if (checked === undefined) checked = true;
  if (iso === undefined) iso = false;

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
      if (s.charAt(i++) != ':') throw new Error();
      var offMin  = num(s, i++)*10 + num(s, i++);
      offset = offHour*3600 + offMin*60;
      if (c == '-') offset = -offset;
      else if (c != '+') throw new Error();
    }

    // timezone - we share this method b/w fromStr and fromIso
    var tz;
    if (iso)
    {
      if (i < s.length) throw new Error();
      tz = fan.sys.TimeZone.fromGmtOffset(offset);
    }
    else
    {
      if (s.charAt(i++) != ' ') throw new Error();
      tz = fan.sys.TimeZone.fromStr(s.substring(i), true);
    }

    // use local var to capture any exceptions
    var instance = fan.sys.DateTime.doMake(year, fan.sys.Month.m_vals.get(month), day, hour, min, sec, ns, offset, tz);
    return instance;
  }
  catch (err)
  {
    if (!checked) return null;
    if (err instanceof fan.sys.ParseErr) throw err;
    throw fan.sys.ParseErr.makeStr("DateTime", s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.equals = function(obj)
{
  if (obj instanceof fan.sys.DateTime)
  {
    return this.m_ticks == obj.m_ticks;
  }
  return false;
}

fan.sys.DateTime.prototype.hash = function()
{
  return this.m_ticks;
}

fan.sys.DateTime.prototype.compare = function(obj)
{
  var that = obj.m_ticks;
  if (this.m_ticks < that) return -1; return this.m_ticks  == that ? 0 : +1;
}

fan.sys.DateTime.prototype.$typeof = function()
{
  return fan.sys.DateTime.$type;
}
//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.ticks = function() { return this.m_ticks; }
fan.sys.DateTime.prototype.date = function() { return fan.sys.Date.make(this.year(), this.month(), this.day()); }
fan.sys.DateTime.prototype.time = function() { return fan.sys.Time.make(this.hour(), this.min(), this.sec(), this.nanoSec()); }
fan.sys.DateTime.prototype.year = function() { return (this.m_fields & 0xff) + 1900; }
fan.sys.DateTime.prototype.month = function() { return fan.sys.Month.m_vals.get((this.m_fields >> 8) & 0xf); }
fan.sys.DateTime.prototype.day = function() { return (this.m_fields >> 12) & 0x1f; }
fan.sys.DateTime.prototype.hour = function() { return (this.m_fields >> 17) & 0x1f; }
fan.sys.DateTime.prototype.min = function() { return (this.m_fields >> 22) & 0x3f; }
fan.sys.DateTime.prototype.sec = function()
{
  var rem = this.m_ticks >= 0 ? this.m_ticks : this.m_ticks - fan.sys.DateTime.yearTicks[0];
  return fan.sys.Int.div((rem % fan.sys.DateTime.nsPerMin),  fan.sys.DateTime.nsPerSec);
}
fan.sys.DateTime.prototype.nanoSec = function()
{
  //var rem = this.m_ticks >= 0 ? this.m_ticks : this.m_ticks - fan.sys.DateTime.yearTicks[0];
  //return rem % fan.sys.DateTime.nsPerSec;
  return this.m_ns;
}
fan.sys.DateTime.prototype.weekday = function() { return fan.sys.Weekday.m_vals.get((this.m_fields >> 28) & 0x7); }
fan.sys.DateTime.prototype.tz = function() { return this.m_tz; }
fan.sys.DateTime.prototype.dst = function() { return ((this.m_fields >> 31) & 0x1) != 0; }
fan.sys.DateTime.prototype.tzAbbr = function() { return this.dst() ? this.m_tz.dstAbbr(this.year()) : this.m_tz.stdAbbr(this.year()); }
fan.sys.DateTime.prototype.dayOfYear = function() { return fan.sys.DateTime.dayOfYear(this.year(), this.month().m_ordinal, this.day())+1; }

fan.sys.DateTime.prototype.weekOfYear = function(startOfWeek)
{
  if (startOfWeek === undefined) startOfWeek = fan.sys.Weekday.localeStartOfWeek();
  return fan.sys.DateTime.weekOfYear(this.year(), this.month().m_ordinal, this.day(), startOfWeek);
}

fan.sys.DateTime.weekOfYear = function(year, month, day, startOfWeek)
{
  var firstWeekday = fan.sys.DateTime.firstWeekday(year, 0); // zero based
  var lastDayInFirstWeek = 7 - (firstWeekday - startOfWeek.m_ordinal);

  // special case for first week
  if (month == 0 && day <= lastDayInFirstWeek) return 1;

  // compute from dayOfYear - lastDayInFirstWeek
  var doy = fan.sys.DateTime.dayOfYear(year, month, day) + 1;
  var woy = Math.floor((doy - lastDayInFirstWeek - 1) / 7);
  return woy + 2; // add first week and make one based
}

fan.sys.DateTime.prototype.hoursInDay = function()
{
  var year  = this.year();
  var month = this.month().m_ordinal;
  var day   = this.day();
  var rule  = this.tz().rule(year);
  if (fan.sys.TimeZone.isDstDate(rule, rule.dstStart, year, month, day)) return 23;
  if (fan.sys.TimeZone.isDstDate(rule, rule.dstEnd, year, month, day))   return 25;
  return 24;
}

/////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toLocale = function(pattern, locale)
{
  if (locale === undefined || locale == null) locale = fan.sys.Locale.cur();
  if (pattern === undefined) pattern = null;

  // locale specific default
  if (pattern == null)
  {
    var pod = fan.sys.Pod.find("sys");
    pattern = fan.sys.Env.cur().locale(pod, "dateTime", "D-MMM-YYYY WWW hh:mm:ss zzz", locale);
  }

  return fan.sys.DateTimeStr.makeDateTime(pattern, locale, this).format();
}

fan.sys.DateTime.fromLocale = function(s, pattern, tz, checked)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();
  if (checked === undefined) checked = true;
  return fan.sys.DateTimeStr.make(pattern, null).parseDateTime(s, tz, checked);
}

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.minusDateTime = function(time)
{
  return fan.sys.Duration.make(this.m_ticks-time.m_ticks);
}

fan.sys.DateTime.prototype.plus = function(duration)
{
  var d = duration.m_ticks;
  if (d == 0) return this;
  return fan.sys.DateTime.makeTicks(this.m_ticks+d, this.m_tz);
}

fan.sys.DateTime.prototype.minus = function(duration)
{
  var d = duration.m_ticks;
  if (d == 0) return this;
  return fan.sys.DateTime.makeTicks(this.m_ticks-d, this.m_tz);
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toTimeZone = function(tz)
{
  if (this.m_tz == tz) return this;
  if (tz == fan.sys.TimeZone.m_rel || this.m_tz == fan.sys.TimeZone.m_rel)
  {
    return fan.sys.DateTime.make(
      this.year(), this.month(), this.day(),
      this.hour(), this.min(), this.sec(), this.nanoSec(), tz);
  }
  else
  {
    return fan.sys.DateTime.makeTicks(this.m_ticks, tz);
  }
}

fan.sys.DateTime.prototype.toUtc = function()
{
  return this.toTimeZone(fan.sys.TimeZone.m_utc);
}

fan.sys.DateTime.prototype.toRel = function()
{
  return this.toTimeZone(fan.sys.TimeZone.m_rel);
}

fan.sys.DateTime.prototype.floor = function(accuracy)
{
  if (this.m_ticks % accuracy.m_ticks == 0) return this;
  return fan.sys.DateTime.makeTicks(this.m_ticks - (this.m_ticks % accuracy.m_ticks), this.m_tz);
}

fan.sys.DateTime.prototype.midnight = function()
{
  return fan.sys.DateTime.make(this.year(), this.month(), this.day(), 0, 0, 0, 0, this.m_tz);
}

fan.sys.DateTime.prototype.isMidnight = function()
{
  return this.hour() == 0 && this.min() == 0 && this.sec() == 0 && this.nanoSec() == 0;
}

fan.sys.DateTime.prototype.toStr = function()
{
  return this.toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz zzzz");
}

fan.sys.DateTime.isLeapYear = function(year)
{
  if ((year & 3) != 0) return false;
  return (year % 100 != 0) || (year % 400 == 0);
}

fan.sys.DateTime.weekdayInMonth = function(year, mon, weekday, pos)
{
  mon = mon.m_ordinal;
  weekday = weekday.m_ordinal;

  // argument checking
  fan.sys.DateTime.checkYear(year);
  if (pos == 0) throw fan.sys.ArgErr.make("Pos is zero");

  // compute the weekday of the 1st of this month (0-6)
  var firstWeekday = fan.sys.DateTime.firstWeekday(year, mon);

  // get number of days in this month
  var numDays = fan.sys.DateTime.numDaysInMonth(year, mon);

  if (pos > 0)
  {
    var day = weekday - firstWeekday + 1;
    if (day <= 0) day = 8 - firstWeekday + weekday;
    day += (pos-1)*7;
    if (day > numDays) throw fan.sys.ArgErr.make("Pos out of range " + pos);
    return day;
  }
  else
  {
    var lastWeekday = (firstWeekday + numDays - 1) % 7;
    var off = lastWeekday - weekday;
    if (off < 0) off = 7 + off;
    off -= (pos+1)*7;
    var day = numDays - off;
    if (day < 1) throw fan.sys.ArgErr.make("Pos out of range " + pos);
    return day;
  }
}

fan.sys.DateTime.dayOfYear = function(year, mon, day)
{
  return fan.sys.DateTime.isLeapYear(year) ?
    fan.sys.DateTime.dayOfYearForFirstOfMonLeap[mon] + day - 1 :
    fan.sys.DateTime.dayOfYearForFirstOfMon[mon] + day - 1;
}

fan.sys.DateTime.numDaysInMonth = function(year, month)
{
  if (month == 1 && fan.sys.DateTime.isLeapYear(year))
    return 29;
  else
    return fan.sys.DateTime.daysInMon[month];
}

fan.sys.DateTime.ticksToYear = function(ticks)
{
  // estimate the year to get us in the ball park, then
  // match the exact year using the yearTicks lookup table
  var year = fan.sys.Int.div(ticks, fan.sys.DateTime.nsPerYear) + 2000;
  if (fan.sys.DateTime.yearTicks[year-1900] > ticks) year--;
  return year;
}

fan.sys.DateTime.firstWeekday = function(year, mon)
{
  // get the 1st day of this month as a day of year (0-365)
  var firstDayOfYear = fan.sys.DateTime.isLeapYear(year)
    ? fan.sys.DateTime.dayOfYearForFirstOfMonLeap[mon]
    : fan.sys.DateTime.dayOfYearForFirstOfMon[mon];

  // compute the weekday of the 1st of this month (0-6)
  return (fan.sys.DateTime.firstWeekdayOfYear[year-1900] + firstDayOfYear) % 7;
}

fan.sys.DateTime.checkYear = function(year)
{
  if (year < 1901 || year > 2099)
    throw fan.sys.ArgErr.make("Year out of range " + year);
}

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toJava = function()
{
  return (this.m_ticks / fan.sys.DateTime.nsPerMilli) + 946684800000;
}

fan.sys.DateTime.fromJava = function(millis, tz, negIsNull)
{
  if (tz === undefined) tz = fan.sys.TimeZone.cur();
  if (negIsNull === undefined) negIsNull = true;
  if (millis <= 0 && negIsNull) return null;
  var ticks = (millis - 946684800000) * fan.sys.DateTime.nsPerMilli;
  return fan.sys.DateTime.makeTicks(ticks, tz);
}

//////////////////////////////////////////////////////////////////////////
// HTTP
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toHttpStr = function()
{
  return this.toTimeZone(fan.sys.TimeZone.utc()).toLocale(
    "WWW, DD MMM YYYY hh:mm:ss", fan.sys.Locale.fromStr("en")) + " GMT";
}

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toIso = function()
{
  return this.toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz");
}

fan.sys.DateTime.fromIso = function(s, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.DateTime.fromStr(s, checked, true);
}

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

fan.sys.DateTime.prototype.toCode = function()
{
  if (this.equals(fan.sys.DateTime.m_defVal)) return "DateTime.defVal";
  return "DateTime(\"" + this.toString() + "\")";
}

//////////////////////////////////////////////////////////////////////////
// Lookup Tables
//////////////////////////////////////////////////////////////////////////

// ns ticks for jan 1 of year 1900-2100
fan.sys.DateTime.yearTicks = [];

// first weekday (0-6) of year indexed by year 1900-2100
fan.sys.DateTime.firstWeekdayOfYear = [];

fan.sys.DateTime.yearTicks[0] = -3155673600000000000; // ns ticks for 1900
fan.sys.DateTime.firstWeekdayOfYear[0] = 1;
for (var i=1; i<202; ++i)
{
  var daysInYear = 365;
  if (fan.sys.DateTime.isLeapYear(i+1900-1)) daysInYear = 366;
  fan.sys.DateTime.yearTicks[i] = fan.sys.DateTime.yearTicks[i-1] + daysInYear * fan.sys.DateTime.nsPerDay;
  fan.sys.DateTime.firstWeekdayOfYear[i] = (fan.sys.DateTime.firstWeekdayOfYear[i-1] + daysInYear) % 7;
}

// number of days in each month indexed by month (0-11)
fan.sys.DateTime.daysInMon     = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
fan.sys.DateTime.daysInMonLeap = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

// day of year (0-365) for 1st day of month (0-11)
fan.sys.DateTime.dayOfYearForFirstOfMon     = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
fan.sys.DateTime.dayOfYearForFirstOfMonLeap = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
for (var i=1; i<12; ++i)
{
  fan.sys.DateTime.dayOfYearForFirstOfMon[i] =
    fan.sys.DateTime.dayOfYearForFirstOfMon[i-1] + fan.sys.DateTime.daysInMon[i-1];

  fan.sys.DateTime.dayOfYearForFirstOfMonLeap[i] =
    fan.sys.DateTime.dayOfYearForFirstOfMonLeap[i-1] + fan.sys.DateTime.daysInMonLeap[i-1];
}

// month and day of month indexed by day of the year (0-365)
fan.sys.DateTime.monForDayOfYear     = [];
fan.sys.DateTime.dayForDayOfYear     = [];
fan.sys.DateTime.monForDayOfYearLeap = [];
fan.sys.DateTime.dayForDayOfYearLeap = [];
fan.sys.DateTime.fillInDayOfYear = function(mon, days, daysInMon, len)
{
  var m = 0, d = 1;
  for (var i=0; i<len; ++i)
  {
    mon[i] = m; days[i] = d++;
    if (d > daysInMon[m]) { m++; d = 1; }
  }
}
fan.sys.DateTime.fillInDayOfYear(fan.sys.DateTime.monForDayOfYear, fan.sys.DateTime.dayForDayOfYear, fan.sys.DateTime.daysInMon, 365);
fan.sys.DateTime.fillInDayOfYear(fan.sys.DateTime.monForDayOfYearLeap, fan.sys.DateTime.dayForDayOfYearLeap, fan.sys.DateTime.daysInMonLeap, 366);

