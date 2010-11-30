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
import java.util.concurrent.atomic.*;

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
    long now = nowTicks();

    DateTime c = cached;
    if (tolerance != null && now - c.ticks <= tolerance.ticks)
        return c;

    return cached = new DateTime(now, TimeZone.cur);
  }

  public static DateTime nowUtc()  { return nowUtc(toleranceDefault); }
  public static DateTime nowUtc(Duration tolerance)
  {
    long now = nowTicks();

    DateTime c = cachedUtc;
    if (tolerance != null && now - c.ticks <= tolerance.ticks)
        return c;

    return cachedUtc = new DateTime(now, TimeZone.utc);
  }

  public static long nowTicks()
  {
    return fromJavaToTicks(System.currentTimeMillis());
  }

  public static long nowUnique()
  {
    synchronized (nowUniqueLock)
    {
      long now = (System.currentTimeMillis() - diffJava) * nsPerMilli;
      if (now <= nowUniqueLast) now = nowUniqueLast+1;
      return nowUniqueLast = now;
    }
  }

  public static DateTime boot()  { return Sys.bootDateTime; }

//////////////////////////////////////////////////////////////////////////
// Constructor - Values
//////////////////////////////////////////////////////////////////////////

  public static DateTime make(long year, Month month, long day, long hour, long min) { return make(year, month, day, hour, min, 0L, 0L, TimeZone.cur); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec) { return make(year, month, day, hour, min, sec, 0L, TimeZone.cur); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns) { return make(year, month, day, hour, min, sec, ns, TimeZone.cur); }
  public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns, TimeZone tz)
  {
    return new DateTime((int)year, month.ord, (int)day, (int)hour, (int)min, (int)sec, ns, Integer.MAX_VALUE, tz);
  }

  DateTime(int year, int month, int day,
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
    this.ticks = ticks;
    this.tz    = tz;
    this.fields   = fields;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - Date,Time
//////////////////////////////////////////////////////////////////////////

  static DateTime makeDT(Date d, Time t) { return makeDT(d, t, TimeZone.cur); }
  static DateTime makeDT(Date d, Time t, TimeZone tz)
  {
    return new DateTime(d.year, d.month, d.day, t.hour, t.min, t.sec, t.ns, Integer.MAX_VALUE, tz);
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - Ticks
//////////////////////////////////////////////////////////////////////////

  public static DateTime makeTicks(long ticks) { return makeTicks(ticks, TimeZone.cur); }
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
    this.tz    = tz;

    // compute the year
    int year = ticksToYear(ticks);

    // get the time zone rule for this year, and
    // offset the working ticks by UTC offset
    TimeZone.Rule rule = tz.rule(year);
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

  public static DateTime fromStr(String s) { return fromStr(s, true, false); }
  public static DateTime fromStr(String s, boolean checked) { return fromStr(s, checked, false); }
  private static DateTime fromStr(String s, boolean checked, boolean iso)
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

      // timezone - we share this method b/w fromStr and fromIso
      TimeZone tz;
      if (iso)
      {
        if (i < s.length()) throw new Exception();
        tz = TimeZone.fromGmtOffset(offset);
      }
      else
      {
        if (s.charAt(i++) != ' ') throw new Exception();
        tz = TimeZone.fromStr(s.substring(i), true);
      }

      return new DateTime(year, month, day, hour, min, sec, ns, offset, tz);
    }
    catch (ParseErr.Val e)
    {
      if (!checked) return null;
      throw e;
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

  public Type typeof()
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
  private final int getMonth() { return (fields >> 8) & 0xf; }

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

  public final TimeZone tz() { return tz; }

  public final boolean dst() { return ((fields >> 31) & 0x1) != 0; }

  public final String tzAbbr() { return dst() ? tz.dstAbbr(year()) : tz.stdAbbr(year()); }

  public final long dayOfYear() { return dayOfYear(getYear(), month().ord, getDay())+1; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public String toLocale() { return toLocale((String)null, null); }
  public String toLocale(String pattern) { return toLocale(pattern, null); }
  private String toLocale(String pattern, Locale locale)
  {
    // locale specific default
    if (pattern == null)
    {
      if (locale == null) locale = Locale.cur();
      pattern = Env.cur().locale(Sys.sysPod, localeKey, "D-MMM-YYYY WWW hh:mm:ss zzz", locale);
    }

    return new DateTimeStr(pattern, locale, this).format();
  }

  public static DateTime fromLocale(String s, String pattern) { return fromLocale(s, pattern, TimeZone.cur(), true); }
  public static DateTime fromLocale(String s, String pattern, TimeZone tz) { return fromLocale(s, pattern, tz, true); }
  public static DateTime fromLocale(String s, String pattern, TimeZone tz, boolean checked)
  {
    return new DateTimeStr(pattern, null).parseDateTime(s, tz, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public Duration minusDateTime(DateTime time)
  {
    return Duration.make(ticks-time.ticks);
  }

  public DateTime plus(Duration duration)
  {
    long d = duration.ticks;
    if (d == 0) return this;
    return makeTicks(ticks+d, tz);
  }

  public DateTime minus(Duration duration)
  {
    long d = duration.ticks;
    if (d == 0) return this;
    return makeTicks(ticks-d, tz);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final DateTime toTimeZone(TimeZone tz)
  {
    if (this.tz == tz) return this;
    if (tz == TimeZone.rel || this.tz == TimeZone.rel)
    {
      return new DateTime(getYear(), getMonth(), getDay(),
                          getHour(), getMin(), getSec(), getNanoSec(),
                          Integer.MAX_VALUE, tz);
    }
    else
    {
      return makeTicks(ticks, tz);
    }
  }

  public final DateTime toUtc() { return toTimeZone(TimeZone.utc); }

  public final DateTime toRel() { return toTimeZone(TimeZone.rel); }

  public final DateTime floor(Duration accuracy)
  {
    if (ticks % accuracy.ticks == 0) return this;
    return makeTicks(ticks - (ticks % accuracy.ticks), tz);
  }

  public final DateTime midnight()
  {
    return make(year(), month(), day(), 0, 0, 0, 0, tz);
  }

  public final boolean isMidnight()
  {
    return hour() == 0 && min() == 0 && sec() == 0 && getNanoSec() == 0;
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
   * NOTE: this is zero based, unlike public Fantom method.
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

  public String toHttpStr()
  {
    return toTimeZone(TimeZone.utc).toLocale("WWW, DD MMM YYYY hh:mm:ss", Locale.en) + " GMT";
  }

  public static DateTime fromHttpStr(String s) { return fromHttpStr(s, true); }
  public static DateTime fromHttpStr(String s, boolean checked)
  {
    synchronized (httpFormats)
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
    }

    if (!checked) return null;
    throw ParseErr.make("Invalid HTTP DateTime: '" + s + "'").val;
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

  public static long fromJavaToTicks(long millis)
  {
    return (millis - diffJava) * nsPerMilli;
  }

  public static DateTime fromJava(long millis) { return fromJava(millis, TimeZone.cur); }
  public static DateTime fromJava(long millis, TimeZone tz)
  {
    if (millis <= 0) return null;
    return new DateTime(fromJavaToTicks(millis), tz);
  }

  public long toJava() { return (ticks / nsPerMilli) + diffJava; }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  public String toIso() { return toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz"); }

  public static DateTime fromIso(String s) { return fromStr(s, true, true); }
  public static DateTime fromIso(String s, boolean checked) { return fromStr(s, checked, true); }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  public String toCode()
  {
    if (equals(defVal)) return "DateTime.defVal";
    return "DateTime(\"" + toString() + "\")";
  }

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
  private static volatile DateTime cached = new DateTime(0, TimeZone.cur);
  private static volatile DateTime cachedUtc = new DateTime(0, TimeZone.utc);
  private static Object nowUniqueLock = new Object();
  private static long nowUniqueLast;
  private static AtomicLong nowTicksCounter = new AtomicLong();
  private static final String localeKey = "dateTime";

  public static final DateTime defVal = make(2000, Month.jan, 1, 0, 0, 0, 0, TimeZone.utc());


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

  private final long ticks;      // ns ticks from 1-Jan-2000 UTC
  private final int fields;      // bitmask of year, month, day, etc
  private final TimeZone tz;     // time used to resolve fields

}