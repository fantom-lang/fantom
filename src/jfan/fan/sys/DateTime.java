//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//   8 Oct 07  Brian Frank  Rename Time -> DateTime
//
package fan.sys;

import java.text.*;
import java.util.*;

/**
 * DateTime represents an absolute instance in time.
 */
public final class DateTime
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  static final long diffJava   = 946684800000L; // 2000-1970 in milliseconds
  static final long nsPerYear  = 365L*24L*60L*60L*1000000000L;
  static final long nsPerDay   = 24L*60L*60L*1000000000L;
  static final long nsPerHour  = 60L*60L*1000000000L;
  static final long nsPerMin   = 60L*1000000000L;
  static final long nsPerSec   = 1000000000L;
  static final long nsPerMilli = 1000000L;
  static final long minTicks   = -3124137600000000000L; // 1901
  static final long maxTicks   = 3155760000000000000L;  // 2100

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static DateTime now()  { return now(toleranceDefault); }
  public static DateTime now(Duration tolerance)
  {
    long now = (System.currentTimeMillis() - diffJava) * nsPerMilli;

    DateTime c = cached;
    if (tolerance != null && now - c.ticks <= tolerance.ticks)
        return c;

    return cached = new DateTime(now, TimeZone.current);
  }

  public static DateTime nowUtc()  { return nowUtc(toleranceDefault); }
  public static DateTime nowUtc(Duration tolerance)
  {
    long now = (System.currentTimeMillis() - diffJava) * nsPerMilli;

    DateTime c = cachedUtc;
    if (tolerance != null && now - c.ticks <= tolerance.ticks)
        return c;

    return cachedUtc = new DateTime(now, TimeZone.utc);
  }

  public static DateTime boot()  { return boot; }

//////////////////////////////////////////////////////////////////////////
// Constructor - Values
//////////////////////////////////////////////////////////////////////////

  public static DateTime make(long year, Month month, long day, long hour, long min) { return make(year, month, day, hour, min, 0L, 0L, TimeZone.current); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec) { return make(year, month, day, hour, min, sec, 0L, TimeZone.current); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns) { return make(year, month, day, hour, min, sec, ns, TimeZone.current); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns, TimeZone tz)
  {
    return new DateTime((int)year, month.ord, (int)day, (int)hour, (int)min, (int)sec, ns, Integer.MAX_VALUE, tz);
  }

  private DateTime(int year, int month, int day,
                   int hour, int min, int sec,
                   long ns,  int knownOffset, TimeZone tz)
  {
    if (year < 1901 || year > 2099) throw ArgErr.make("year " + year).val;
    if (month < 0 || month > 11)    throw ArgErr.make("month " + month).val;
    if (day < 1 || day > numDaysInMonth(year, month)) throw ArgErr.make("day " + day).val;
    if (hour < 0 || hour > 23)      throw ArgErr.make("hour " + hour).val;
    if (min < 0 || min > 59)        throw ArgErr.make("min " + min).val;
    if (sec < 0 || sec > 59)        throw ArgErr.make("sec " + sec).val;
    if (ns < 0 || ns > 999999999L)  throw ArgErr.make("ns " + ns).val;

    // compute ticks for UTC
    int dayOfYear = dayOfYear(year, month, day);
    int timeInSec = hour*3600 + min*60 + sec;
    long ticks = (long)yearTicks[year-1900] +
                 (long)dayOfYear * nsPerDay +
                 (long)timeInSec * nsPerSec +
                 ns;

    // adjust for timezone and dst (we might know the UTC offset)
    TimeZone.Rule rule = tz.rule(year);
    boolean dst;
    if (knownOffset == Integer.MAX_VALUE)
    {
      // don't know offset so compute from timezone rule
      ticks -= (long)rule.offset * nsPerSec;
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

    // compute weekday
    int weekday = (firstWeekday(year, month) + day - 1) % 7;

    // fields
    int fields = 0;
    fields |= ((year-1900) & 0xff) << 0;
    fields |= (month & 0xf) << 8;
    fields |= (day & 0x1f)  << 12;
    fields |= (hour & 0x1f) << 17;
    fields |= (min  & 0x3f) << 22;
    fields |= (weekday & 0x7) << 28;
    fields |= (dst ? 1 : 0) << 31;

    // commit
    this.ticks    = ticks;
    this.timeZone = tz;
    this.fields   = fields;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - Ticks
//////////////////////////////////////////////////////////////////////////

  public static DateTime makeTicks(long ticks) { return makeTicks(ticks, TimeZone.current); }
  public static DateTime makeTicks(long ticks, TimeZone tz)
  {
    return new DateTime(ticks, tz);
  }

  private DateTime(long ticks, TimeZone tz)
  {
    // check boundary conditions 1901 to 2099
    if (ticks < minTicks || ticks >= maxTicks)
      throw ArgErr.make("Ticks out of range 1901 to 2099").val;

    // save ticks, time zone
    this.ticks = ticks;
    this.timeZone = tz;

    // compute the year
    int year = ticksToYear(ticks);

    // get the time zone rule for this year, and
    // offset the working ticks by UTC offset
    TimeZone.Rule rule = timeZone.rule(year);
    ticks += rule.offset * nsPerSec;

    // compute the day and month; we may need to execute this
    // code block up to three times:
    //   1st: using standard time
    //   2nd: using daylight offset (if in dst)
    //   3rd: using standard time (if dst pushed us back into std)
    int month, day, dstOffset = 0;
    long rem;
    while (true)
    {
      // recompute year based on working ticks
      year = ticksToYear(ticks);
      rem = ticks - yearTicks[year-1900];
      if (rem < 0) rem += nsPerYear;

      // compute day of the year
      int dayOfYear = (int)(rem/nsPerDay);
      rem %= nsPerDay;

      // use lookup tables map day of year to month and day
      if (isLeapYear(year))
      {
        month = monForDayOfYearLeap[dayOfYear];
        day   = dayForDayOfYearLeap[dayOfYear];
      }
      else
      {
        month = monForDayOfYear[dayOfYear];
        day   = dayForDayOfYear[dayOfYear];
      }

      // if dstOffset is set to max, then this is
      // the third time thru the loop: std->dst->std
      if (dstOffset == Integer.MAX_VALUE) { dstOffset = 0; break; }

      // if dstOffset is non-zero we have run this
      // loop twice to recompute the date for dst
      if (dstOffset != 0)
      {
        // if our dst rule is wall time based, then we need to
        // recompute to see if dst wall time pushed us back
        // into dst - if so then run through the loop a third
        // time to get us back to standard time
        if (rule.isWallTime() && TimeZone.dstOffset(rule, year, month, day, (int)(rem/nsPerSec)) == 0)
        {
          ticks -= dstOffset * nsPerSec;
          dstOffset = Integer.MAX_VALUE;
          continue;
        }
        break;
      }

      // first time in loop; check for daylight saving time,
      // and if dst is in effect then re-run this loop with
      // modified working ticks
      dstOffset = TimeZone.dstOffset(rule, year, month, day, (int)(rem/nsPerSec));
      if (dstOffset == 0) break;
      ticks += dstOffset * nsPerSec;
    }

    // compute time of day
    int hour = (int)(rem / nsPerHour);  rem %= nsPerHour;
    int min  = (int)(rem / nsPerMin);   rem %= nsPerMin;

    // compute weekday
    int weekday = (firstWeekday(year, month) + day - 1) % 7;

    // fields
    int fields = 0;
    fields |= ((year-1900) & 0xff) << 0;
    fields |= (month & 0xf) << 8;
    fields |= (day & 0x1f)  << 12;
    fields |= (hour & 0x1f) << 17;
    fields |= (min  & 0x3f) << 22;
    fields |= (weekday & 0x7) << 28;
    fields |= (dstOffset != 0 ? 1 : 0) << 31;
    this.fields = fields;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - FromStr
//////////////////////////////////////////////////////////////////////////

  public static DateTime fromStr(String s) { return fromStr(s, true); }
  public static DateTime fromStr(String s, boolean checked)
  {
    try
    {
      // YYYY-MM-DD'T'hh:mm:ss
      int year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
      int month = num(s, 5)*10   + num(s, 6) - 1;
      int day   = num(s, 8)*10   + num(s, 9);
      int hour  = num(s, 11)*10  + num(s, 12);
      int min   = num(s, 14)*10  + num(s, 15);
      int sec   = num(s, 17)*10  + num(s, 18);

      // check separator symbols
      if (s.charAt(4)  != '-' || s.charAt(7)  != '-' ||
          s.charAt(10) != 'T' || s.charAt(13) != ':' ||
          s.charAt(16) != ':')
        throw new Exception();

      // optional .FFFFFFFFF
      int i = 19;
      int ns = 0;
      int tenth = 100000000;
      if (s.charAt(i) == '.')
      {
        ++i;
        while (true)
        {
          int c = s.charAt(i);
          if (c < '0' || c > '9') break;
          ns += (c - '0') * tenth;
          tenth /= 10;
          ++i;
        }
      }

      // zone offset
      int offset = 0;
      int c = s.charAt(i++);
      if (c != 'Z')
      {
        int offHour = num(s, i++)*10 + num(s, i++);
        if (s.charAt(i++) != ':') throw new Exception();
        int offMin  = num(s, i++)*10 + num(s, i++);
        offset = offHour*3600 + offMin*60;
        if (c == '-') offset = -offset;
        else if (c != '+') throw new Exception();
      }

      // timezone
      if (s.charAt(i++) != ' ') throw new Exception();
      TimeZone tz = TimeZone.fromStr(s.substring(i), true);

      return new DateTime(year, month, day, hour, min, sec, ns, offset, tz);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("DateTime", s).val;
    }
  }

  static int num(String s, int index)
  {
    return s.charAt(index) - '0';
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    if (obj instanceof DateTime)
    {
      return ticks == ((DateTime)obj).ticks;
    }
    return false;
  }

  public long compare(Object obj)
  {
    long that = ((DateTime)obj).ticks;
    if (ticks < that) return -1; return ticks  == that ? 0 : +1;
  }

  public int hashCode()
  {
    return (int)(ticks ^ (ticks >>> 32));
  }

  public long hash()
  {
    return ticks;
  }

  public Type type()
  {
    return Sys.DateTimeType;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public final long ticks() { return ticks; }

  public final Date date() { return new Date(getYear(), month().ord, getDay()); }

  public final Time time() { return new Time(getHour(), getMin(), getSec(), getNanoSec()); }

  public final long year() { return (fields & 0xff) + 1900; }
  public final int getYear() { return (fields & 0xff) + 1900; }

  public final Month month() { return Month.array[(fields >> 8) & 0xf]; }

  public final long day() { return (fields >> 12) & 0x1f; }
  public final int getDay() { return (fields >> 12) & 0x1f; }

  public final long hour() { return (fields >> 17) & 0x1f; }
  public final int getHour() { return (fields >> 17) & 0x1f; }

  public final long min() { return (fields >> 22) & 0x3f; }
  public final int getMin() { return (fields >> 22) & 0x3f; }

  public final long sec() { return getSec(); }
  public final int getSec()
  {
    long rem = ticks >= 0 ? ticks : ticks - yearTicks[0];
    return (int)((rem % nsPerMin) / nsPerSec);
  }

  public final long nanoSec() { return getNanoSec(); }
  public final int getNanoSec()
  {
    long rem = ticks >= 0 ? ticks : ticks - yearTicks[0];
    return (int)(rem % nsPerSec);
  }

  public final Weekday weekday() { return Weekday.array[(fields >> 28) & 0x7]; }

  public final TimeZone timeZone() { return timeZone; }

  public final boolean dst() { return ((fields >> 31) & 0x1) != 0; }

  public final String timeZoneAbbr() { return dst() ? timeZone.dstAbbr(year()) : timeZone.stdAbbr(year()); }

  public final long dayOfYear() { return dayOfYear(getYear(), month().ord, getDay())+1; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public String toLocale() { return toLocale((String)null); }
  public String toLocale(String pattern)
  {
    // locale specific default
    Locale locale = null;
    if (pattern == null)
    {
      if (locale == null) locale = Locale.current();
      pattern = locale.get("sys", localeKey);
    }

    // process pattern
    StringBuilder s = new StringBuilder();
    int len = pattern.length();
    for (int i=0; i<len; ++i)
    {
      // character
      int c = pattern.charAt(i);

      // literals
      if (c == '\'')
      {
        while (true)
        {
          ++i;
          if (i >= len) throw ArgErr.make("Invalid pattern: unterminated literal").val;
          c = pattern.charAt(i);
          if (c == '\'') break;
          s.append((char)c);
        }
        continue;
      }

      // character count
      int n = 1;
      while (i+1<len && pattern.charAt(i+1) == c) { ++i; ++n; }

      // switch
      boolean invalidNum = false;
      switch (c)
      {
        case 'Y':
          int year = getYear();
          switch (n)
          {
            case 2:  year %= 100; if (year < 10) s.append('0');
            case 4:  s.append(year); break;
            default: invalidNum = true;
          }
          break;

        case 'M':
          Month mon = month();
          switch (n)
          {
            case 4:
              if (locale == null) locale = Locale.current();
              s.append(mon.full(locale));
              break;
            case 3:
              if (locale == null) locale = Locale.current();
              s.append(mon.abbr(locale));
              break;
            case 2:  if (mon.ord+1 < 10) s.append('0');
            case 1:  s.append(mon.ord+1); break;
            default: invalidNum = true;
          }
          break;

        case 'D':
          int day = getDay();
          switch (n)
          {
            case 2:  if (day < 10) s.append('0');
            case 1:  s.append(day); break;
            default: invalidNum = true;
          }
          break;

        case 'W':
          Weekday weekday = weekday();
          switch (n)
          {
            case 4:
              if (locale == null) locale = Locale.current();
              s.append(weekday.full(locale));
              break;
            case 3:
              if (locale == null) locale = Locale.current();
              s.append(weekday.abbr(locale));
              break;
            default: invalidNum = true;
          }
          break;

        case 'h':
        case 'k':
          int hour = getHour();
          if (c == 'k')
          {
            if (hour == 0) hour = 12;
            else if (hour > 12) hour -= 12;
          }
          switch (n)
          {
            case 2:  if (hour < 10) s.append('0');
            case 1:  s.append(hour); break;
            default: invalidNum = true;
          }
          break;

        case 'm':
          int min = getMin();
          switch (n)
          {
            case 2:  if (min < 10) s.append('0');
            case 1:  s.append(min); break;
            default: invalidNum = true;
          }
          break;

        case 's':
          int sec = getSec();
          switch (n)
          {
            case 2:  if (sec < 10) s.append('0');
            case 1:  s.append(sec); break;
            default: invalidNum = true;
          }
          break;

        case 'a':
          switch (n)
          {
            case 1:  s.append(getHour() < 12 ? "AM" : "PM"); break;
            default: invalidNum = true;
          }
          break;

        case 'f':
        case 'F':
          int req = 0, opt = 0; // required, optional
          if (c == 'F') opt = n;
          else
          {
            req = n;
            while (i+1<len && pattern.charAt(i+1) == 'F') { ++i; ++opt; }
          }
          int frac = getNanoSec();
          for (int x=0, tenth=100000000; x<9; ++x)
          {
            if (req > 0) req--;
            else
            {
              if (frac == 0 || opt <= 0) break;
              opt--;
            }
            s.append(frac/tenth);
            frac %= tenth;
            tenth /= 10;
          }
          break;

        case 'z':
          TimeZone.Rule rule = timeZone.rule(getYear());
          boolean dst = dst();
          switch (n)
          {
            case 1:
              int offset = rule.offset;
              if (dst) offset += rule.dstOffset;
              if (offset == 0) { s.append('Z'); break; }
              if (offset < 0) { s.append('-'); offset = -offset; }
              else { s.append('+'); }
              int zh = offset / 3600;
              int zm = (offset % 3600) / 60;
              if (zh < 10) s.append('0'); s.append(zh).append(':');
              if (zm < 10) s.append('0'); s.append(zm);
              break;
            case 3:
              s.append(dst ? rule.dstAbbr : rule.stdAbbr);
              break;
            case 4:
              s.append(timeZone.name());
              break;
            default:
              invalidNum = true;
              break;
          }
          break;

        default:
          if (c != 'T' && FanInt.isAlpha(c))
            throw ArgErr.make("Invalid pattern: unsupported char '" + (char)c + "'").val;

          // don't display symbol between ss.FFF if fractions is zero
          if (i+1<len && pattern.charAt(i+1) == 'F' && getNanoSec() == 0)
            break;

          s.append((char)c);
      }

      // if invalid number of characters
      if (invalidNum)
        throw ArgErr.make("Invalid pattern: unsupported num '" + (char)c + "' (x" + n + ")").val;
    }

    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public Duration minus(DateTime time)
  {
    return Duration.make(ticks-time.ticks);
  }

  public DateTime plus(Duration duration)
  {
    long d = duration.ticks;
    if (d == 0) return this;
    return makeTicks(ticks+d, timeZone);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final DateTime toTimeZone(TimeZone tz)
  {
    if (timeZone == tz) return this;
    return makeTicks(ticks, tz);
  }

  public final DateTime toUtc()
  {
    if (timeZone == TimeZone.utc) return this;
    return makeTicks(ticks, TimeZone.utc);
  }

  public final DateTime floor(Duration accuracy)
  {
    if (ticks % accuracy.ticks == 0) return this;
    return makeTicks(ticks - (ticks % accuracy.ticks), timeZone);
  }

  public final String toStr()
  {
    return toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz zzzz");
  }

  public static boolean isLeapYear(long year) { return isLeapYear((int)year); }
  public static boolean isLeapYear(int year)
  {
    if ((year & 3) != 0) return false;
    return (year % 100 != 0) || (year % 400 == 0);
  }

  public static long weekdayInMonth(long year, Month mon, Weekday weekday, long pos)
  {
    return weekdayInMonth((int)year, mon.ord, weekday.ord, (int)pos);
  }
  public static int weekdayInMonth(int year, int mon, int weekday, int pos)
  {
    // argument checking
    checkYear(year);
    if (pos == 0) throw ArgErr.make("Pos is zero").val;

    // compute the weekday of the 1st of this month (0-6)
    int firstWeekday = firstWeekday(year, mon);

    // get number of days in this month
    int numDays = numDaysInMonth(year, mon);

    if (pos > 0)
    {
      int day = weekday - firstWeekday + 1;
      if (day <= 0) day = 8 - firstWeekday + weekday;
      day += (pos-1)*7;
      if (day > numDays) throw ArgErr.make("Pos out of range " + pos).val;
      return day;
    }
    else
    {
      int lastWeekday = (firstWeekday + numDays - 1) % 7;
      int off = lastWeekday - weekday;
      if (off < 0) off = 7 + off;
      off -= (pos+1)*7;
      int day = numDays - off;
      if (day < 1) throw ArgErr.make("Pos out of range " + pos).val;
      return day;
    }
  }

  /**
   * Static util for day of year (0-365).
   * NOTE: this is zero based, unlike public Fan method.
   */
  public static int dayOfYear(int year, int mon, int day)
  {
    return isLeapYear(year) ?
      dayOfYearForFirstOfMonLeap[mon] + day - 1 :
      dayOfYearForFirstOfMon[mon] + day - 1;
  }

  /**
   * Get the number days in the specified month (0-11).
   */
  static int numDaysInMonth(int year, int month)
  {
    if (month == 1 && isLeapYear(year))
      return 29;
    else
      return daysInMon[month];
  }

  /**
   * Compute the year for ns ticks.
   */
  static int ticksToYear(long ticks)
  {
    // estimate the year to get us in the ball park, then
    // match the exact year using the yearTicks lookup table
    int year = (int)(ticks/nsPerYear) + 2000;
    if (yearTicks[year-1900] > ticks) year--;
    return year;
  }

  /**
   * Get the first weekday of the specified year and month (0-11).
   */
  static int firstWeekday(int year, int mon)
  {
    // get the 1st day of this month as a day of year (0-365)
    int firstDayOfYear = isLeapYear(year) ? dayOfYearForFirstOfMonLeap[mon] : dayOfYearForFirstOfMon[mon];

    // compute the weekday of the 1st of this month (0-6)
    return (firstWeekdayOfYear[year-1900] + firstDayOfYear) % 7;
  }

  /**
   * If not valid year range 1901 to 2099 throw ArgErr.
   */
  static void checkYear(int year)
  {
    if (year < 1901 || year > 2099)
      throw ArgErr.make("Year out of range " + year).val;
  }

//////////////////////////////////////////////////////////////////////////
// HTTP
//////////////////////////////////////////////////////////////////////////

  public static DateTime fromHttpStr(String s) { return fromHttpStr(s, true); }
  public static DateTime fromHttpStr(String s, boolean checked)
  {
    for (int i=0; i<httpFormats.length; ++i)
    {
      try
      {
        java.util.Date date = httpFormats[i].parse(s);
        return fromJava(date.getTime());
      }
      catch (Exception e)
      {
      }
    }

    if (!checked) return null;
    throw ParseErr.make("Invalid HTTP DateTime: '" + s + "'").val;
  }

  public String toHttpStr()
  {
    return httpFormats[0].format(new java.util.Date(toJava()));
  }

  private static final SimpleDateFormat httpFormats[] =
  {
    new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz", java.util.Locale.US),
    new SimpleDateFormat("EEEEEE, dd-MMM-yy HH:mm:ss zzz", java.util.Locale.US),
    new SimpleDateFormat("EEE MMMM d HH:mm:ss yyyy", java.util.Locale.US)
  };
  static
  {
    java.util.TimeZone gmt = java.util.TimeZone.getTimeZone("GMT");
    for (int i=0; i<httpFormats.length; ++i)
      httpFormats[i].setTimeZone(gmt);
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  public static DateTime fromJava(long millis) { return fromJava(millis, TimeZone.current); }
  public static DateTime fromJava(long millis, TimeZone tz)
  {
    if (millis <= 0) return null;
    return new DateTime((millis-diffJava)*nsPerMilli, tz);
  }

  public long toJava() { return (ticks / nsPerMilli) + diffJava; }

//////////////////////////////////////////////////////////////////////////
// Lookup Tables
//////////////////////////////////////////////////////////////////////////

  // ns ticks for jan 1 of year 1900-2100
  static long[] yearTicks = new long[202];

  // first weekday (0-6) of year indexed by year 1900-2100
  static byte[] firstWeekdayOfYear = new byte[202];

  static
  {
    yearTicks[0] = -3155673600000000000L; // ns ticks for 1900
    firstWeekdayOfYear[0] = 1;
    for (int i=1; i<yearTicks.length; ++i)
    {
      int daysInYear = 365;
      if (isLeapYear(i+1900-1)) daysInYear = 366;
      yearTicks[i] = yearTicks[i-1] + daysInYear*nsPerDay;
      firstWeekdayOfYear[i] = (byte)((firstWeekdayOfYear[i-1] + daysInYear) % 7);
    }
  }

  // number of days in each month indexed by month (0-11)
  static final int daysInMon[]     = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
  static final int daysInMonLeap[] = { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

  // day of year (0-365) for 1st day of month (0-11)
  static final int dayOfYearForFirstOfMon[] = new int[12];
  static final int dayOfYearForFirstOfMonLeap[] = new int[12];
  static
  {
    for (int i=1; i<12; ++i)
    {
      dayOfYearForFirstOfMon[i] = dayOfYearForFirstOfMon[i-1] + daysInMon[i-1];
      dayOfYearForFirstOfMonLeap[i] = dayOfYearForFirstOfMonLeap[i-1] + daysInMonLeap[i-1];
    }
  }

  // month and day of month indexed by day of the year (0-365)
  static byte[] monForDayOfYear     = new byte[365];
  static byte[] dayForDayOfYear     = new byte[365];
  static byte[] monForDayOfYearLeap = new byte[366];
  static byte[] dayForDayOfYearLeap = new byte[366];
  static
  {
    fillInDayOfYear(monForDayOfYear, dayForDayOfYear, daysInMon);
    fillInDayOfYear(monForDayOfYearLeap, dayForDayOfYearLeap, daysInMonLeap);
  }

  static void fillInDayOfYear(byte[] mon, byte[] days, int[] daysInMon)
  {
    int m = 0, d = 1;
    for (int i=0; i<mon.length; ++i)
    {
      mon[i] = (byte)m; days[i] = (byte)(d++);
      if (d > daysInMon[m]) { m++; d = 1; }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Duration toleranceDefault = Duration.makeMillis(250);
  private static volatile DateTime cached = new DateTime(0, TimeZone.current);
  private static volatile DateTime cachedUtc = new DateTime(0, TimeZone.utc);
  private static final String localeKey = "dateTime";
  private static final DateTime boot = now();


  // Fields Bitmask
  //   Field       Width    Mask   Start Bit
  //   ---------   ------   -----  ---------
  //   year-1900   8 bits   0xff   0
  //   month       4 bits   0xf    8
  //   day         5 bits   0x1f   12
  //   hour        5 bits   0x1f   17
  //   min         6 bits   0x3f   22
  //   weekday     3 bits   0x7    28
  //   dst         1 bit    0x1    31

  private final long ticks;          // ns ticks from 1-Jan-2000 UTC
  private final int fields;          // bitmask of year, month, day, etc
  private final TimeZone timeZone;   // time used to resolve fields

}