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

  public static Date today()
  {
    return DateTime.now().date();
  }

  public static Date make(long year, Month month, long day)
  {
    return new Date((int)year, month.ord, (int)day);
  }

  Date(int year, int month, int day)
  {
    if (month < 0 || month > 11)    throw ArgErr.make("month " + month).val;
    if (day < 1 || day > DateTime.numDaysInMonth(year, month)) throw ArgErr.make("day " + day).val;

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

      // check separator symbols
      if (s.charAt(4)  != '-' || s.charAt(7)  != '-')
        throw new Exception();

      return new Date(year, month, day);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Date", s).val;
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
    return toLocale("YYYY-MM-DD");
  }

  public Type type()
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

        default:
          if (FanInt.isAlpha(c))
            throw ArgErr.make("Invalid pattern: unsupported char '" + (char)c + "'").val;

          s.append((char)c);
      }

      // if invalid number of characters
      if (invalidNum)
        throw ArgErr.make("Invalid pattern: unsupported num '" + (char)c + "' (x" + n + ")").val;
    }

    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final String localeKey = "date";


  private final short year;
  private final byte month;
  private final byte day;

}