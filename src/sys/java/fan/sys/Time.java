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
 * Time represents a time of day independent of a specific
 * date or timezone.
 */
public final class Time
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Time now() { return DateTime.now().time(); }
  public static Time now(TimeZone tz)
  {
    return DateTime.makeTicks(DateTime.nowTicks(), tz).time();
  }

  public static Time make(long hour, long min) { return make(hour, min, 0L, 0L); }
  public static Time make(long hour, long min, long sec) { return make(hour, min, sec, 0L); }
  public static Time make(long hour, long min, long sec, long ns)
  {
    return new Time((int)hour, (int)min, (int)sec, (int)ns);
  }

  Time(int hour, int min, int sec, int ns)
  {
    if (hour < 0 || hour > 23)     throw ArgErr.make("hour " + hour);
    if (min < 0 || min > 59)       throw ArgErr.make("min " + min);
    if (sec < 0 || sec > 59)       throw ArgErr.make("sec " + sec);
    if (ns < 0 || ns > 999999999)  throw ArgErr.make("ns " + ns);

    this.hour = (byte)hour;
    this.min  = (byte)min;
    this.sec  = (byte)sec;
    this.ns   = ns;
  }

  public static Time fromStr(String s) { return fromStr(s, true); }
  public static Time fromStr(String s, boolean checked)
  {
    try
    {
      // hh:mm:ss
      int hour  = num(s, 0)*10  + num(s, 1);
      int min   = num(s, 3)*10  + num(s, 4);
      int sec   = num(s, 6)*10  + num(s, 7);

      // check separator symbols
      if (s.charAt(2) != ':' || s.charAt(5) != ':')
        throw new Exception();

      // optional .FFFFFFFFF
      int i = 8;
      int ns = 0;
      int tenth = 100000000;
      int len = s.length();
      if (i < len && s.charAt(i) == '.')
      {
        ++i;
        while (i < len)
        {
          int c = s.charAt(i);
          if (c < '0' || c > '9') break;
          ns += (c - '0') * tenth;
          tenth /= 10;
          ++i;
        }
      }

      // verify everything has been parsed
      if (i < s.length()) throw new Exception();

      return new Time(hour, min, sec, ns);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Time", s);
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
    if (obj instanceof Time)
    {
      Time x = (Time)obj;
      return hour == x.hour && min == x.min && sec == x.sec && ns == x.ns;
    }
    return false;
  }

  public long compare(Object obj)
  {
    Time x = (Time)obj;
    if (hour == x.hour)
    {
      if (min == x.min)
      {
        if (sec == x.sec)
        {
          if (ns == x.ns) return 0;
          return ns < x.ns ? -1 : +1;
        }
        return sec < x.sec ? -1 : +1;
      }
      return min < x.min ? -1 : +1;
    }
    return hour < x.hour ? -1 : +1;
  }

  public int hashCode()
  {
    return (hour << 24) ^ (min << 20) ^ (sec << 16) ^ns;
  }

  public long hash()
  {
    return (hour << 24) ^ (min << 20) ^ (sec << 16) ^ns;
  }

  public final String toStr()
  {
    return toLocale("hh:mm:ss.FFFFFFFFF");
  }

  public Type typeof()
  {
    return Sys.TimeType;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public final long hour() { return hour; }
  public final int getHour() { return hour; }

  public final long min() { return min; }
  public final int getMin() { return min; }

  public final long sec() { return sec; }
  public final int getSec() { return sec; }

  public final long nanoSec() { return ns; }
  public final int getNanoSec() { return ns; }

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
      pattern = Env.cur().locale(Sys.sysPod, localeKey, "hh:mm:ss", locale);
    }

    return new DateTimeStr(pattern, locale, this).format();
  }

  public static Time fromLocale(String s, String pattern) { return fromLocale(s, pattern, true); }
  public static Time fromLocale(String s, String pattern, boolean checked)
  {
    return new DateTimeStr(pattern, null).parseTime(s, checked);
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  public String toIso() { return toStr(); }

  public static Time fromIso(String s) { return fromStr(s, true); }
  public static Time fromIso(String s, boolean checked) { return fromStr(s, checked); }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  public static Time fromDuration(Duration d)
  {
    long ticks = d.ticks;
    if (ticks == 0) return defVal;

    if (ticks < 0 || ticks > Duration.nsPerDay )
      throw ArgErr.make("Duration out of range: " + d);

    int hour = (int)(ticks / Duration.nsPerHr);  ticks %= Duration.nsPerHr;
    int min  = (int)(ticks / Duration.nsPerMin); ticks %= Duration.nsPerMin;
    int sec  = (int)(ticks / Duration.nsPerSec); ticks %= Duration.nsPerSec;
    int ns   = (int)ticks;

    return new Time(hour, min, sec, ns);
  }

  public Duration toDuration()
  {
    return Duration.make(hour*Duration.nsPerHr +
                         min*Duration.nsPerMin +
                         sec*Duration.nsPerSec +
                         ns);
  }

  public DateTime toDateTime(Date d) { return DateTime.makeDT(d, this); }
  public DateTime toDateTime(Date d, TimeZone tz) { return DateTime.makeDT(d, this, tz); }

  public String toCode()
  {
    if (equals(defVal)) return "Time.defVal";
    return "Time(\"" + toString() + "\")";
  }

  public boolean isMidnight()
  {
    return this.equals(defVal);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final String localeKey = "time";

  public static final Time defVal = new Time(0, 0, 0, 0);

  final byte hour;
  final byte min;
  final byte sec;
  final int ns;

}