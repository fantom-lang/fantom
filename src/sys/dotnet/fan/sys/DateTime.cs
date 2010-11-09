//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 07  Andy Frank  Creation
//   8 Oct 07   Andy Frank  Rename Time -> DateTime
//

using System.Text;
using System.Globalization;

namespace Fan.Sys
{
  /// <summary>
  /// DateTime represents an absolute instance in time.
  /// </summary>
  public sealed class DateTime : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////

    internal const long diffJava   = 946684800000L; // 2000-1970 in milliseconds
    internal const long diffDotnet = 630822816000000000L; // 2000-0001 in 100's of nanoseconds
    internal const long nsPerYear  = 365L*24L*60L*60L*1000000000L;
    internal const long nsPerDay   = 24L*60L*60L*1000000000L;
    internal const long nsPerHour  = 60L*60L*1000000000L;
    internal const long nsPerMin   = 60L*1000000000L;
    internal const long nsPerSec   = 1000000000L;
    internal const long nsPerMilli = 1000000L;
    internal const long nsPerTick  = 100L;  // num of ns in a .NET 'Tick'
    internal const long minTicks   = -3124137600000000000L; // 1901
    internal const long maxTicks   = 3155760000000000000L;  // 2100

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static DateTime now()  { return now(toleranceDefault); }
    public static DateTime now(Duration tolerance)
    {
      long now = (System.DateTime.Now.Ticks - diffDotnet) * nsPerTick;

      DateTime c = cached;
      if (tolerance != null && now - c.m_ticks <= tolerance.m_ticks)
          return c;

      return cached = new DateTime(now, TimeZone.m_cur);
    }

    public static DateTime nowUtc()  { return nowUtc(toleranceDefault); }
    public static DateTime nowUtc(Duration tolerance)
    {
      long now = (System.DateTime.Now.Ticks - diffDotnet) * nsPerTick;

      DateTime c = cachedUtc;
      if (tolerance != null && now - c.m_ticks <= tolerance.m_ticks)
          return c;

      return cachedUtc = new DateTime(now, TimeZone.m_utc);
    }

    public static long nowTicks()
    {
      return (System.DateTime.Now.Ticks - diffDotnet) * nsPerTick;
    }

    public static long nowUnique()
    {
      lock (m_nowUniqueLock)
      {
        long now = (System.DateTime.Now.Ticks - diffDotnet) * nsPerTick;
        if (now <= m_nowUniqueLast) now = m_nowUniqueLast+1;
        return m_nowUniqueLast = now;
      }
    }

    public static DateTime boot()  { return m_boot; }

  //////////////////////////////////////////////////////////////////////////
  // Constructor - Values
  //////////////////////////////////////////////////////////////////////////

    public static DateTime make(long year, Month month, long day, long hour, long min) { return make(year, month, day, hour, min, 0, 0, TimeZone.m_cur); }
    public static DateTime make(long year, Month month, long day, long hour, long min, long sec) { return make(year, month, day, hour, min, sec, 0, TimeZone.m_cur); }
    public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns) { return make(year, month, day, hour, min, sec, ns, TimeZone.m_cur); }
    public static DateTime make(long year, Month month, long day, long hour, long min, long sec, long ns, TimeZone tz)
    {
      return new DateTime((int)year, month.ord, (int)day, (int)hour, (int)min, (int)sec, ns, System.Int32.MaxValue, tz);
    }

    internal DateTime(int year, int month, int day,
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
      int doy = dayOfYear(year, month, day);
      int timeInSec = hour*3600 + min*60 + sec;
      long ticks = (long)yearTicks[year-1900] +
                   (long)doy * nsPerDay +
                   (long)timeInSec * nsPerSec +
                   ns;

      // adjust for timezone and dst (we might know the UTC offset)
      TimeZone.Rule rule = tz.rule(year);
      bool dst;
      if (knownOffset == System.Int32.MaxValue)
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
      this.m_ticks  = ticks;
      this.m_tz     = tz;
      this.m_fields = fields;
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor - Date, Time
  //////////////////////////////////////////////////////////////////////////

    internal static DateTime makeDT(Date d, Time t) { return makeDT(d, t, TimeZone.m_cur); }
    internal static DateTime makeDT(Date d, Time t, TimeZone tz)
    {
      return new DateTime(d.m_year, d.m_month, d.m_day, t.m_hour, t.m_min, t.m_sec, t.m_ns, System.Int32.MaxValue, tz);
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor - Ticks
  //////////////////////////////////////////////////////////////////////////

    public static DateTime makeTicks(long ticks) { return makeTicks(ticks, TimeZone.m_cur); }
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
      this.m_ticks = ticks;
      this.m_tz = tz;

      // compute the year
      int year = ticksToYear(ticks);

      // get the time zone rule for this year, and
      // offset the working ticks by UTC offset
      TimeZone.Rule rule = m_tz.rule(year);
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
        if (dstOffset == System.Int32.MaxValue) { dstOffset = 0; break; }

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
            dstOffset = System.Int32.MaxValue;
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
      this.m_fields = fields;
    }

//////////////////////////////////////////////////////////////////////////
// Constructor - FromStr
//////////////////////////////////////////////////////////////////////////

    public static DateTime fromStr(string s) { return fromStr(s, true, false); }
    public static DateTime fromStr(string s, bool check) { return fromStr(s, check, false); }
    private static DateTime fromStr(string s, bool check, bool iso)
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
        if (s[4]  != '-' || s[7]  != '-' ||
            s[10] != 'T' || s[13] != ':' ||
            s[16] != ':')
          throw new System.Exception();

        // optional .FFFFFFFFF
        int i = 19;
        int ns = 0;
        int tenth = 100000000;
        if (s[i] == '.')
        {
          ++i;
          while (true)
          {
            int c = s[i];
            if (c < '0' || c > '9') break;
            ns += (c - '0') * tenth;
            tenth /= 10;
            ++i;
          }
        }

        // zone offset
        int offset = 0;
        int ch = s[i++];
        if (ch != 'Z')
        {
          int offHour = num(s, i++)*10 + num(s, i++);
          if (s[i++] != ':') throw new System.Exception();
          int offMin  = num(s, i++)*10 + num(s, i++);
          offset = offHour*3600 + offMin*60;
          if (ch == '-') offset = -offset;
          else if (ch != '+') throw new System.Exception();
        }

        // timezone - we share this method b/w fromStr and fromIso
        TimeZone tz;
        if (iso)
        {
          if (i < s.Length) throw new System.Exception();
          tz = TimeZone.fromGmtOffset(offset);
        }
        else
        {
          if (s[i++] != ' ') throw new System.Exception();
          tz = TimeZone.fromStr(s.Substring(i), true);
        }

        return new DateTime(year, month, day, hour, min, sec, ns, offset, tz);
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("DateTime", s).val;

      }
    }

    static int num(string s, int index)
    {
      return s[index] - '0';
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override bool Equals(object obj)
    {
      if (obj is DateTime)
      {
        return m_ticks == (obj as DateTime).m_ticks;
      }
      return false;
    }

    public override long compare(object obj)
    {
      long that = (obj as DateTime).m_ticks;
      if (m_ticks < that) return -1; return m_ticks == that ? 0 : +1;
    }

    public override int GetHashCode()
    {
      return (int)(m_ticks ^ (m_ticks >> 32));
    }

    public override long hash()
    {
      return m_ticks;
    }

    public override Type @typeof()
    {
      return Sys.DateTimeType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public Date date() { return new Date(getYear(), month().ord, getDay()); }

    public Time time() { return new Time(getHour(), getMin(), getSec(), getNanoSec()); }

    public long ticks() { return m_ticks; }
    public long getTicks() { return m_ticks; }

    public long year() { return (m_fields & 0xff) + 1900; }
    public int getYear() { return (m_fields & 0xff) + 1900; }

    public Month month() { return Month.array[(m_fields >> 8) & 0xf]; }
    private int getMonth() { return (m_fields >> 8) & 0xf; }

    public long day() { return (m_fields >> 12) & 0x1f; }
    public int getDay() { return (m_fields >> 12) & 0x1f; }

    public long hour() { return (m_fields >> 17) & 0x1f; }
    public int getHour() { return (m_fields >> 17) & 0x1f; }

    public long min() { return (m_fields >> 22) & 0x3f; }
    public int getMin() { return (m_fields >> 22) & 0x3f; }

    public long sec() { return getSec(); }
    public int getSec()
    {
      long rem = m_ticks >= 0 ? m_ticks : m_ticks - yearTicks[0];
      return (int)((rem % nsPerMin) / nsPerSec);
    }

    public long nanoSec() { return getNanoSec(); }
    public int getNanoSec()
    {
      long rem = m_ticks >= 0 ? m_ticks : m_ticks - yearTicks[0];
      return (int)(rem % nsPerSec);
    }

    public Weekday weekday() { return Weekday.array[(m_fields >> 28) & 0x7]; }

    public TimeZone tz() { return m_tz; }

    public bool dst() { return ((m_fields >> 31) & 0x1) != 0; }
    public bool getDST()  { return ((m_fields >> 31) & 0x1) != 0; }

    public string tzAbbr() { return getDST() ? m_tz.dstAbbr(year()) : m_tz.stdAbbr(year()); }

    public long dayOfYear() { return dayOfYear(getYear(), month().ord, getDay())+1; }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public string toLocale() { return toLocale((string)null); }
    public string toLocale(string pattern)
    {
      // locale specific default
      Locale locale = null;
      if (pattern == null)
      {
        if (locale == null) locale = Locale.cur();
        pattern = Env.cur().locale(Sys.m_sysPod, m_localeKey, "D-MMM-YYYY WWW hh:mm:ss zzz", locale);
      }

      return new DateTimeStr(pattern, locale, this).format();
    }

    public static DateTime fromLocale(string s, string pattern) { return fromLocale(s, pattern, TimeZone.cur(), true); }
    public static DateTime fromLocale(string s, string pattern, TimeZone tz) { return fromLocale(s, pattern, tz, true); }
    public static DateTime fromLocale(string s, string pattern, TimeZone tz, bool check)
    {
      return new DateTimeStr(pattern, null).parseDateTime(s, tz, check);
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Duration minusDateTime(DateTime time)
    {
      return Duration.make(m_ticks-time.m_ticks);
    }

    public DateTime plus(Duration duration)
    {
      long d = duration.m_ticks;
      if (d == 0) return this;
      return makeTicks(m_ticks+d, m_tz);
    }

    public DateTime minus(Duration duration)
    {
      long d = duration.m_ticks;
      if (d == 0) return this;
      return makeTicks(m_ticks-d, m_tz);
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public DateTime toTimeZone(TimeZone tz)
    {
      if (m_tz == tz) return this;
      if (tz == TimeZone.m_rel || this.m_tz == TimeZone.m_rel)
      {
        return new DateTime(getYear(), getMonth(), getDay(),
                            getHour(), getMin(), getSec(), getNanoSec(),
                            System.Int32.MaxValue, tz);
      }
      return makeTicks(m_ticks, tz);
    }

    public DateTime toUtc() { return toTimeZone(TimeZone.m_utc); }

    public DateTime toRel() { return toTimeZone(TimeZone.m_rel); }

    public DateTime floor(Duration accuracy)
    {
      if (m_ticks % accuracy.m_ticks == 0) return this;
      return makeTicks(m_ticks - (m_ticks % accuracy.m_ticks), m_tz);
    }

    public DateTime midnight()
    {
      return make(year(), month(), day(), 0, 0, 0, 0, m_tz);
    }

    public bool isMidnight()
    {
      return hour() == 0 && min() == 0 && sec() == 0 && getNanoSec() == 0;
    }

    public override string toStr()
    {
      return toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz zzzz");
    }

    public static bool isLeapYear(long year) { return isLeapYear((int)year); }
    public static bool isLeapYear(int year)
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
      int fw = firstWeekday(year, mon);

      // get number of days in this month
      int numDays = numDaysInMonth(year, mon);

      if (pos > 0)
      {
        int day = weekday - fw + 1;
        if (day <= 0) day = 8 - fw + weekday;
        day += (pos-1)*7;
        if (day > numDays) throw ArgErr.make("Pos out of range " + pos).val;
        return day;
      }
      else
      {
        int lastWeekday = (fw + numDays - 1) % 7;
        int off = lastWeekday - weekday;
        if (off < 0) off = 7 + off;
        off -= (pos+1)*7;
        int day = numDays - off;
        if (day < 1) throw ArgErr.make("Pos out of range " + pos).val;
        return day;
      }
    }

    /// <summary>
    /// Static util for day of year (0-365).
    /// NOTE: this is zero based, unlike public Fantom method.
    /// </summary>
    public static int dayOfYear(int year, int mon, int day)
    {
      return isLeapYear(year) ?
        dayOfYearForFirstOfMonLeap[mon] + day - 1 :
        dayOfYearForFirstOfMon[mon] + day - 1;
    }

    /// <summary>
    /// Get the number days in the specified month (0-11).
    /// </summary>
    internal static int numDaysInMonth(int year, int month)
    {
      if (month == 1 && isLeapYear(year))
        return 29;
      else
        return daysInMon[month];
    }

    /// <summary>
    /// Compute the year for ns ticks.
    /// </summary>
    static int ticksToYear(long ticks)
    {
      // estimate the year to get us in the ball park, then
      // match the exact year using the yearTicks lookup table
      int year = (int)(ticks/nsPerYear) + 2000;
      if (yearTicks[year-1900] > ticks) year--;
      return year;
    }

    /// <summary>
    /// Get the first weekday of the specified year and month (0-11).
    /// </summary>
    internal static int firstWeekday(int year, int mon)
    {
      // get the 1st day of this month as a day of year (0-365)
      int firstDayOfYear = isLeapYear(year) ? dayOfYearForFirstOfMonLeap[mon] : dayOfYearForFirstOfMon[mon];

      // compute the weekday of the 1st of this month (0-6)
      return (firstWeekdayOfYear[year-1900] + firstDayOfYear) % 7;
    }

    /// <summary>
    /// If not valid year range 1901 to 2099 throw ArgErr.
    /// </summary>
    static void checkYear(int year)
    {
      if (year < 1901 || year > 2099)
        throw ArgErr.make("Year out of range " + year).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // HTTP
  //////////////////////////////////////////////////////////////////////////

    public static DateTime fromHttpStr(string s) { return fromHttpStr(s, true); }
    public static DateTime fromHttpStr(string s, bool check)
    {
      for (int i=0; i<httpFormats.Length; ++i)
      {
        try
        {
          System.DateTime date = System.DateTime.ParseExact(s, httpFormats,
            CultureInfo.InvariantCulture, DateTimeStyles.AllowInnerWhite |
            DateTimeStyles.AdjustToUniversal);
          return dotnet(date.Ticks);
        }
        catch (System.Exception)
        {
        }
      }

      if (!check) return null;
      throw ParseErr.make("Invalid HTTP DateTime: '" + s + "'").val;
    }

    public string toHttpStr()
    {
      return new System.DateTime(dotnet()).ToString(httpFormats[0]);
    }

    static readonly string[] httpFormats = new string[]
    {
      @"ddd, dd MMM yyyy HH:mm:ss G\MT",
      @"dddd, dd-MMM-yy HH:mm:ss G\MT",
      @"ddd MMM d HH:mm:ss yyyy"
    };

  //////////////////////////////////////////////////////////////////////////
  // Java
  //////////////////////////////////////////////////////////////////////////

    public static DateTime fromJava(long millis) { return fromJava(millis, TimeZone.m_cur); }
    public static DateTime fromJava(long millis, TimeZone tz)
    {
      if (millis <= 0) return null;
      return new DateTime((millis-diffJava)*nsPerMilli, TimeZone.m_cur);
    }

    public long toJava() { return (m_ticks / nsPerMilli) + diffJava; }

  //////////////////////////////////////////////////////////////////////////
  // .NET
  //////////////////////////////////////////////////////////////////////////

    public static DateTime dotnet(long dotnetTicks)
    {
      if (dotnetTicks <= 0) return null;
      return new DateTime((dotnetTicks-diffDotnet)*nsPerTick, TimeZone.m_cur);
    }

    public long dotnet() { return (m_ticks / nsPerTick) + diffDotnet; }

  //////////////////////////////////////////////////////////////////////////
  // ISO 8601
  //////////////////////////////////////////////////////////////////////////

    public string toIso() { return toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz"); }

    public static DateTime fromIso(string s) { return fromStr(s, true, true); }
    public static DateTime fromIso(string s, bool check) { return fromStr(s, check, true); }

  //////////////////////////////////////////////////////////////////////////
  // Misc
  //////////////////////////////////////////////////////////////////////////

    public string toCode()
    {
      if (Equals(m_defVal)) return "DateTime.defVal";
      return "DateTime(\"" + ToString() + "\")";
    }

  //////////////////////////////////////////////////////////////////////////
  // Lookup Tables
  //////////////////////////////////////////////////////////////////////////

    // ns ticks for jan 1 of year 1900-2100
    internal static long[] yearTicks = new long[202];

    // first weekday (0-6) of year indexed by year 1900-2100
    internal static byte[] firstWeekdayOfYear = new byte[202];

    // number of days in each month indexed by month (0-11)
    internal static readonly int[] daysInMon     = new int[] { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    internal static readonly int[] daysInMonLeap = new int[] { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

    // day of year (0-365) for 1st day of month (0-11)
    internal static readonly int[] dayOfYearForFirstOfMon = new int[12];
    internal static readonly int[] dayOfYearForFirstOfMonLeap = new int[12];

    // month and day of month indexed by day of the year (0-365)
    internal static byte[] monForDayOfYear     = new byte[365];
    internal static byte[] dayForDayOfYear     = new byte[365];
    internal static byte[] monForDayOfYearLeap = new byte[366];
    internal static byte[] dayForDayOfYearLeap = new byte[366];

    static void fillInDayOfYear(byte[] mon, byte[] days, int[] daysInMon)
    {
      int m = 0, d = 1;
      for (int i=0; i<mon.Length; ++i)
      {
        mon[i] = (byte)m; days[i] = (byte)(d++);
        if (d > daysInMon[m]) { m++; d = 1; }
      }
    }

    static DateTime()
    {
      yearTicks[0] = -3155673600000000000L; // ns ticks for 1900
      firstWeekdayOfYear[0] = 1;
      for (int i=1; i<yearTicks.Length; ++i)
      {
        int daysInYear = 365;
        if (isLeapYear(i+1900-1)) daysInYear = 366;
        yearTicks[i] = yearTicks[i-1] + daysInYear*nsPerDay;
        firstWeekdayOfYear[i] = (byte)((firstWeekdayOfYear[i-1] + daysInYear) % 7);
      }

      for (int i=1; i<12; ++i)
      {
        dayOfYearForFirstOfMon[i] = dayOfYearForFirstOfMon[i-1] + daysInMon[i-1];
        dayOfYearForFirstOfMonLeap[i] = dayOfYearForFirstOfMonLeap[i-1] + daysInMonLeap[i-1];
      }

      fillInDayOfYear(monForDayOfYear, dayForDayOfYear, daysInMon);
      fillInDayOfYear(monForDayOfYearLeap, dayForDayOfYearLeap, daysInMonLeap);

      m_boot = now();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static readonly Duration toleranceDefault = Duration.makeMillis(250);
    static volatile DateTime cached = new DateTime(0, TimeZone.m_cur);
    static volatile DateTime cachedUtc = new DateTime(0, TimeZone.m_utc);
    static readonly DateTime m_boot;
    static readonly object m_nowUniqueLock = new object();
    static long m_nowUniqueLast;
    static readonly string m_localeKey = "dateTime";

    public static readonly DateTime m_defVal = make(2000, Month.m_jan, 1, 0, 0, 0, 0, TimeZone.utc());

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

    readonly long m_ticks;          // ns ticks from 1-Jan-2000 UTC
    readonly int m_fields;          // bitmask of year, month, day, etc
    readonly TimeZone m_tz;         // time used to resolve fields

  }
}