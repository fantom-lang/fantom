//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//
using System.Text;
using System.Globalization;

namespace Fan.Sys
{
  /// <summary>
  /// Date represents a day in time independent of a timezone.
  /// </summary>
  public sealed class Date : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Date today() { return DateTime.now().date(); }
    public static Date today(TimeZone tz)
    {
      return DateTime.makeTicks(DateTime.nowTicks(), tz).date();
    }

    public static Date make(long year, Month month, long day)
    {
      return new Date((int)year, month.ord, (int)day);
    }

    internal Date(int year, int month, int day)
    {
      if (month < 0 || month > 11)    throw ArgErr.make("month " + month).val;
      if (day < 1 || day > DateTime.numDaysInMonth(year, month)) throw ArgErr.make("day " + day).val;

      this.m_year  = (short)year;
      this.m_month = (byte)month;
      this.m_day   = (byte)day;
    }

    public static Date fromStr(string s) { return fromStr(s, true); }
    public static Date fromStr(string s, bool check)
    {
      try
      {
        // YYYY-MM-DD
        int year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
        int month = num(s, 5)*10   + num(s, 6) - 1;
        int day   = num(s, 8)*10   + num(s, 9);

        // check separator symbols
        if (s[4]  != '-' || s[7]  != '-' || s.Length != 10)
          throw new System.Exception();

        return new Date(year, month, day);
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Date", s).val;
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
      if (obj is Date)
      {
        Date x = (Date)obj;
        return m_year == x.m_year && m_month == x.m_month && m_day == x.m_day;
      }
      return false;
    }

    public override long compare(object that)
    {
      Date x = (Date)that;
      if (m_year == x.m_year)
      {
        if (m_month == x.m_month)
        {
          if (m_day == x.m_day) return 0;
          return m_day < x.m_day ? -1 : +1;
        }
        return m_month < x.m_month ? -1 : +1;
      }
      return m_year < x.m_year ? -1 : +1;
    }

    public override int GetHashCode()
    {
      return (m_year << 16) ^ (m_month << 8) ^ m_day;
    }

    public override long hash()
    {
      return (m_year << 16) ^ (m_month << 8) ^ m_day;
    }

    public override string toStr()
    {
      return toLocale("YYYY-MM-DD");
    }

    public override Type @typeof()
    {
      return Sys.DateType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public long year() { return m_year; }
    public int getYear() { return m_year; }

    public Month month() { return Month.array[m_month]; }

    public long day() { return m_day; }
    public int getDay() { return m_day; }

    public Weekday weekday()
    {
      int weekday = (DateTime.firstWeekday(m_year, m_month) + m_day - 1) % 7;
      return Weekday.array[weekday];
    }

    public long dayOfYear()
    {
      return DateTime.dayOfYear(getYear(), month().ord, getDay())+1;
    }

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
        pattern = Env.cur().locale(Sys.m_sysPod, m_localeKey, "D-MMM-YYYY", locale);
      }

      return new DateTimeStr(pattern, locale, this).format();
    }

    public static Date fromLocale(string s, string pattern) { return fromLocale(s, pattern, true); }
    public static Date fromLocale(string s, string pattern, bool check)
    {
      return new DateTimeStr(pattern, null).parseDate(s, check);
    }

  //////////////////////////////////////////////////////////////////////////
  // ISO 8601
  //////////////////////////////////////////////////////////////////////////

    public string toIso() { return toStr(); }

    public static Date fromIso(string s) { return fromStr(s, true); }
    public static Date fromIso(string s, bool check) { return fromStr(s, check); }

  //////////////////////////////////////////////////////////////////////////
  // Past/Future
  //////////////////////////////////////////////////////////////////////////

    public Date plus(Duration d) { return plus(d.m_ticks); }
    public Date minus(Duration d) { return plus(-d.m_ticks); }
    private Date plus(long ticks)
    {
      // check even number of days
      if (ticks % Duration.nsPerDay != 0)
        throw ArgErr.make("Duration must be even num of days").val;

      int year = this.m_year;
      int month = this.m_month;
      int day = this.m_day;

      int numDays = (int)(ticks / Duration.nsPerDay);
      int dayIncr = numDays < 0 ? +1 : -1;
      while (numDays != 0)
      {
        if (numDays > 0)
        {
          day++;
          if (day > numDaysInMon(year, month))
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
            day = numDaysInMon(year, month);
          }
          numDays++;
        }
      }

      return new Date(year, month, day);
    }

    public Duration minusDate(Date that)
    {
      // short circuit if equal
      if (this.Equals(that)) return Duration.Zero;

      // compute so that a < b
      Date a = this;
      Date b = that;
      if (a.compare(b) > 0) { b = this; a = that; }

      // compute difference in days
      long days = 0;
      if (a.m_year == b.m_year)
      {
        days = b.dayOfYear() - a.dayOfYear();
      }
      else
      {
        days = (DateTime.isLeapYear(a.m_year) ? 366 : 365) - a.dayOfYear();
        days += b.dayOfYear();
        for (int i=a.m_year+1; i<b.m_year; ++i)
          days += DateTime.isLeapYear(i) ? 366 : 365;
      }

      // negate if necessary if a was this
      if (a == this) days = -days;

      // map days into ns ticks
      return Duration.make(days * Duration.nsPerDay);
    }

    private static int numDaysInMon(int year, int mon)
    {
      if (DateTime.isLeapYear(year))
        return DateTime.daysInMonLeap[mon];
      else
        return DateTime.daysInMon[mon];
    }

    public Date firstOfMonth()
    {
      if (m_day == 1) return this;
      return new Date(m_year, m_month, 1);
    }

    public Date lastOfMonth()
    {
      int last = (int)month().numDays(m_year);
      if (m_day == last) return this;
      return new Date(m_year, m_month, last);
    }

  //////////////////////////////////////////////////////////////////////////
  // Misc
  //////////////////////////////////////////////////////////////////////////

    public bool isYesterday() { return Equals(today().plus(Duration.m_negOneDay)); }
    public bool isToday()     { return Equals(today()); }
    public bool isTomorrow()  { return Equals(today().plus(Duration.m_oneDay)); }

    public DateTime toDateTime(Time t) { return DateTime.makeDT(this, t); }
    public DateTime toDateTime(Time t, TimeZone tz) { return DateTime.makeDT(this, t, tz); }

    public DateTime midnight() { return DateTime.makeDT(this, Time.m_defVal); }
    public DateTime midnight(TimeZone tz) { return DateTime.makeDT(this, Time.m_defVal, tz); }

    public string toCode()
    {
      if (Equals(m_defVal)) return "Date.defVal";
      return "Date(\"" + ToString() + "\")";
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static readonly string m_localeKey = "date";

    public static readonly Date m_defVal = new Date(2000, 0, 1);

    internal readonly short m_year;
    internal readonly byte m_month;
    internal readonly byte m_day;

  }
}