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

  public static Time now()
  {
    return DateTime.now().time();
  }

  public static Time make(long hour, long min) { return make(hour, min, 0L, 0L); }
  public static Time make(long hour, long min, long sec) { return make(hour, min, sec, 0L); }
  public static Time make(long hour, long min, long sec, long ns)
  {
    return new Time((int)hour, (int)min, (int)sec, (int)ns);
  }

  Time(int hour, int min, int sec, int ns)
  {
    if (hour < 0 || hour > 23)     throw ArgErr.make("hour " + hour).val;
    if (min < 0 || min > 59)       throw ArgErr.make("min " + min).val;
    if (sec < 0 || sec > 59)       throw ArgErr.make("sec " + sec).val;
    if (ns < 0 || ns > 999999999)  throw ArgErr.make("ns " + ns).val;

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
      throw ParseErr.make("Time", s).val;
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

  public Type type()
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

        default:
          if (FanInt.isAlpha(c))
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
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  public String toIso() { return toStr(); }

  public static Time fromIso(String s) { return fromStr(s, true); }
  public static Time fromIso(String s, boolean checked) { return fromStr(s, checked); }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

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