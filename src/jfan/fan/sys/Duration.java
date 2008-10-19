//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 05  Brian Frank  Creation
//
package fan.sys;

import fanx.serial.*;

/**
 * Duration
 */
public final class Duration
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Duration fromStr(String s) { return fromStr(s, true); }
  public static Duration fromStr(String s, boolean checked)
  {
    //   ns:   nanoseconds  (x 1)
    //   ms:   milliseconds (x 1,000,000)
    //   sec:  seconds      (x 1,000,000,000)
    //   min:  minutes      (x 60,000,000,000)
    //   hr:   hours        (x 3,600,000,000,000)
    //   day:  days         (x 86,400,000,000,000)
    try
    {
      int len = s.length();
      int x1 = s.charAt(len-1);
      int x2 = s.charAt(len-2);
      int x3 = s.charAt(len-3);
      boolean dot = s.indexOf('.') > 0;

      long mult = -1;
      int suffixLen  = -1;
      switch (x1)
      {
        case 's':
          if (x2 == 'n') { mult=1L; suffixLen=2; } // ns
          if (x2 == 'm') { mult=1000000L; suffixLen=2; } // ms
          break;
        case 'c':
          if (x2 == 'e' && x3 == 's') { mult=1000000000L; suffixLen=3; } // sec
          break;
        case 'n':
          if (x2 == 'i' && x3 == 'm') { mult=60000000000L; suffixLen=3; } // min
          break;
        case 'r':
          if (x2 == 'h') { mult=3600000000000L; suffixLen=2; } // hr
          break;
        case 'y':
          if (x2 == 'a' && x3 == 'd') { mult=86400000000000L; suffixLen=3; } // day
          break;
      }

      if (mult < 0) throw new Exception();

      s = s.substring(0, len-suffixLen);
      if (dot)
        return make((long)(Double.parseDouble(s)*(double)mult));
      else
        return make(Long.parseLong(s)*mult);
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Duration",  s).val;
    }
  }

  public static Duration make(Long ticks) { return make(ticks.longValue()); }
  public static Duration make(long ticks)
  {
    if (ticks == 0) return Zero;
    return new Duration(ticks);
  }

  public static Duration makeMillis(long ms)
  {
    return make(ms*1000000L);
  }

  public static Duration makeSec(long secs)
  {
    return make(secs*1000000000L);
  }

  public static Duration now()
  {
    return new Duration(System.nanoTime());
  }

  public static Duration boot()
  {
    return boot;
  }

  public static Duration uptime()
  {
    return new Duration(System.nanoTime() - boot.ticks);
  }

  private Duration(long ticks)
  {
    this.ticks = ticks;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    if (obj instanceof Duration)
      return ticks == ((Duration)obj).ticks;
    else
      return false;
  }

  public final Long compare(Object obj)
  {
    long that = ((Duration)obj).ticks;
    if (ticks < that) return FanInt.LT; return ticks  == that ? FanInt.EQ : FanInt.GT;
  }

  public final int hashCode()
  {
    return (int)(ticks ^ (ticks >>> 32));
  }

  public final Long hash()
  {
    return Long.valueOf(ticks);
  }

  public final Long ticks()
  {
    return Long.valueOf(ticks);
  }

  public final Type type()
  {
    return Sys.DurationType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public final Duration negate()
  {
    return make(-ticks);
  }

  public final Duration plus(Duration x)
  {
    return make(ticks + x.ticks);
  }

  public final Duration minus(Duration x)
  {
    return make(ticks - x.ticks);
  }

  public final Duration mult(double x)
  {
    return make((long)(ticks * x));
  }

  public final Duration div(double x)
  {
    return make((long)(ticks / x));
  }

  public final Duration floor(Duration accuracy)
  {
    if (ticks % accuracy.ticks == 0) return this;
    return make(ticks - (ticks % accuracy.ticks));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr()
  {
    return str();
  }

  public void encode(ObjEncoder out)
  {
    out.w(str());
  }

  public String str()
  {
    if (ticks == 0) return "0ns";

    // if clean millisecond boundary
    long ns = ticks;
    if (ns % nsPerMilli == 0)
    {
      if (ns % nsPerDay == 0) return ns/nsPerDay + "day";
      if (ns % nsPerHr  == 0) return ns/nsPerHr  + "hr";
      if (ns % nsPerMin == 0) return ns/nsPerMin + "min";
      if (ns % nsPerSec == 0) return ns/nsPerSec + "sec";
      return ns/nsPerMilli + "ms";
    }

    // return in nanoseconds
    return ns + "ns";
  }

  public final Long toMillis()
  {
    return Long.valueOf(ticks/nsPerMilli);
  }

  public final Long toSec()
  {
    return Long.valueOf(ticks/nsPerSec);
  }

  public final Long toMin()
  {
    return Long.valueOf(ticks/nsPerMin);
  }

  public final Long toHour()
  {
    return Long.valueOf(ticks/nsPerHr);
  }

  public final Long toDay()
  {
    return Long.valueOf(ticks/nsPerDay);
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public String toLocale()
  {
    long ticks = this.ticks;

    // less than 1000ns Xns
    if (ticks < 1000L) return ticks + "ns";

    // less than 2ms X.XXXms
    if (ticks < 2*nsPerMilli)
    {
      StringBuilder s = new StringBuilder();
      long ms = ticks/nsPerMilli;
      long us = (ticks - ms*nsPerMilli)/1000L;
      s.append(ms);
      s.append('.');
      if (us < 100) s.append('0');
      if (us < 10)  s.append('0');
      s.append(us);
      if (s.charAt(s.length()-1) == '0') s.setLength(s.length()-1);
      if (s.charAt(s.length()-1) == '0') s.setLength(s.length()-1);
      s.append("ms");
      return s.toString();
    }

    // less than 2sec Xms
    if (ticks < 2L*nsPerSec)   return (ticks/nsPerMilli) + "ms";

    // less than 2min Xsec
    if (ticks < 1L*nsPerMin)   return (ticks/nsPerSec) + "sec";

    // [Xdays] [Xhr] Xmin Xsec
    long days  = ticks/nsPerDay; ticks -= days*nsPerDay;
    long hr  = ticks/nsPerHr;    ticks -= hr*nsPerHr;
    long min = ticks/nsPerMin;   ticks -= min*nsPerMin;
    long sec = ticks/nsPerSec;

    StringBuilder s = new StringBuilder();
    if (days > 0) s.append(days).append(days == 1 ? "day " : "days ");
    if (days > 0 || hr > 0) s.append(hr).append("hr ");
    s.append(min).append("min ");
    s.append(sec).append("sec");
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  public long sec()
  {
    return ticks/1000000000L;
  }

  public long millis()
  {
    return ticks/1000000L;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Duration Zero = new Duration(0);
  public static final long nsPerDay   = 86400000000000L;
  public static final long nsPerHr    = 3600000000000L;
  public static final long nsPerMin   = 60000000000L;
  public static final long nsPerSec   = 1000000000L;
  public static final long nsPerMilli = 1000000L;
  private static final Duration boot = now();

  public final long ticks;
  private String str;

}