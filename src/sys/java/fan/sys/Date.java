//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//
package fan.sys;

import java.text.*;
import java.util.*;

/**
 * Date represents a day in time independent of a timezone.
 */
public final class Date
  extends FanObj
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

  Date(int year, int month, int day)
  {
    if (month < 0 || month > 11)    throw ArgErr.make("month " + month);
    if (day < 1 || day > DateTime.numDaysInMonth(year, month)) throw ArgErr.make("day " + day);

    this.year  = (short)year;
    this.month = (byte)month;
    this.day   = (byte)day;
  }

  public static Date fromStr(String s) { return fromStr(s, true); }
  public static Date fromStr(String s, boolean checked)
  {
    try
    {
      // YYYY-MM-DD
      int year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
      int month = num(s, 5)*10   + num(s, 6) - 1;
      int day   = num(s, 8)*10   + num(s, 9);

      // check separator symbols and length
      if (s.charAt(4)  != '-' || s.charAt(7)  != '-' || s.length() != 10)
        throw new Exception();

      return new Date(year, month, day);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Date", s);
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
    if (obj instanceof Date)
    {
      Date x = (Date)obj;
      return year == x.year && month == x.month && day == x.day;
    }
    return false;
  }

  public long compare(Object that)
  {
    Date x = (Date)that;
    if (year == x.year)
    {
      if (month == x.month)
      {
        if (day == x.day) return 0;
        return day < x.day ? -1 : +1;
      }
      return month < x.month ? -1 : +1;
    }
    return year < x.year ? -1 : +1;
  }

  public int hashCode()
  {
    return (year << 16) ^ (month << 8) ^ day;
  }

  public long hash()
  {
    return (year << 16) ^ (month << 8) ^ day;
  }

  public final String toStr()
  {
    if (str == null) str = toLocale("YYYY-MM-DD");
    return str;
  }

  public Type typeof()
  {
    return Sys.DateType;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public final long year() { return year; }
  public final int getYear() { return year; }

  public final Month month() { return Month.array[month]; }

  public final long day() { return day; }
  public final int getDay() { return day; }

  public final Weekday weekday()
  {
    int weekday = (DateTime.firstWeekday(year, month) + day - 1) % 7;
    return Weekday.array[weekday];
  }

  public final long dayOfYear()
  {
    return DateTime.dayOfYear(getYear(), month().ord, getDay())+1;
  }

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
      if (locale == null) locale = Locale.cur();
      pattern = Env.cur().locale(Sys.sysPod, localeKey, "D-MMM-YYYY", locale);
    }

    return new DateTimeStr(pattern, locale, this).format();
  }

  public static Date fromLocale(String s, String pattern) { return fromLocale(s, pattern, true); }
  public static Date fromLocale(String s, String pattern, boolean checked)
  {
    return new DateTimeStr(pattern, null).parseDate(s, checked);
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  public String toIso() { return toStr(); }

  public static Date fromIso(String s) { return fromStr(s, true); }
  public static Date fromIso(String s, boolean checked) { return fromStr(s, checked); }

//////////////////////////////////////////////////////////////////////////
// Past/Future
//////////////////////////////////////////////////////////////////////////

  public final Date plus(Duration d) { return plus(d.ticks()); }
  public final Date minus(Duration d) { return plus(-d.ticks()); }

  private Date plus(long ticks)
  {
    // check even number of days
    if (ticks % Duration.nsPerDay != 0)
      throw ArgErr.make("Duration must be even num of days");

    int year = this.year;
    int month = this.month;
    int day = this.day;

    int numDays = (int)(ticks / Duration.nsPerDay);
    int dayIncr = numDays < 0 ? +1 : -1;
    while (numDays != 0)
    {
      if (numDays > 0)
      {
        day++;
        if (day > numDays(year, month))
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
          day = numDays(year, month);
        }
        numDays++;
      }
    }

    return new Date(year, month, day);
  }

  public final Duration minusDate(Date that)
  {
    // short circuit if equal
    if (this.equals(that)) return Duration.Zero;

    // compute so that a < b
    Date a = this;
    Date b = that;
    if (a.compare(b) > 0) { b = this; a = that; }

    // compute difference in days
    long days = 0;
    if (a.year == b.year)
    {
      days = b.dayOfYear() - a.dayOfYear();
    }
    else
    {
      days = (DateTime.isLeapYear(a.year) ? 366 : 365) - a.dayOfYear();
      days += b.dayOfYear();
      for (int i=a.year+1; i<b.year; ++i)
        days += DateTime.isLeapYear(i) ? 366 : 365;
    }

    // negate if necessary if a was this
    if (a == this) days = -days;

    // map days into ns ticks
    return Duration.make(days * Duration.nsPerDay);
  }

  private static int numDays(int year, int mon)
  {
    if (DateTime.isLeapYear(year))
      return DateTime.daysInMonLeap[mon];
    else
      return DateTime.daysInMon[mon];
  }

  public final Date firstOfMonth()
  {
    if (day == 1) return this;
    return new Date(year, month, 1);
  }

  public final Date lastOfMonth()
  {
    int last = (int)month().numDays(year);
    if (day == last) return this;
    return new Date(year, month, last);
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  public boolean isYesterday() { return equals(today().plus(Duration.negOneDay)); }
  public boolean isToday()     { return equals(today()); }
  public boolean isTomorrow()  { return equals(today().plus(Duration.oneDay)); }

  public DateTime toDateTime(Time t) { return DateTime.makeDT(this, t); }
  public DateTime toDateTime(Time t, TimeZone tz) { return DateTime.makeDT(this, t, tz); }

  public DateTime midnight() { return DateTime.makeDT(this, Time.defVal); }
  public DateTime midnight(TimeZone tz) { return DateTime.makeDT(this, Time.defVal, tz); }

  public String toCode()
  {
    if (equals(defVal)) return "Date.defVal";
    return "Date(\"" + toString() + "\")";
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final String localeKey = "date";

  public static final Date defVal = new Date(2000, 0, 1);

  final short year;
  final byte month;
  final byte day;
  private String str;

}