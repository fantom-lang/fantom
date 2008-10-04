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

  public static Duration fromStr(Str s) { return fromStr(s, Bool.True); }
  public static Duration fromStr(Str s, Bool checked)
  {
    //   ns:   nanoseconds  (x 1)
    //   ms:   milliseconds (x 1,000,000)
    //   sec:  seconds      (x 1,000,000,000)
    //   min:  minutes      (x 60,000,000,000)
    //   hr:   hours        (x 3,600,000,000,000)
    //   day:  days         (x 86,400,000,000,000)
    try
    {
      String str = s.val;
      int len = str.length();
      int x1 = str.charAt(len-1);
      int x2 = str.charAt(len-2);
      int x3 = str.charAt(len-3);
      boolean dot = str.indexOf('.') > 0;

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

      str = str.substring(0, len-suffixLen);
      if (dot)
        return make((long)(Double.parseDouble(str)*(double)mult));
      else
        return make(Long.parseLong(str)*mult);
    }
    catch (Exception e)
    {
      if (!checked.val) return null;
      throw ParseErr.make("Duration",  s).val;
    }
  }

  public static Duration make(Int ticks) { return make(ticks.val); }
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

  public final Bool _equals(Object obj)
  {
    if (obj instanceof Duration)
      return ticks == ((Duration)obj).ticks ? Bool.True : Bool.False;
    else
      return Bool.False;
  }

  public final Int compare(Object obj)
  {
    long that = ((Duration)obj).ticks;
    if (ticks < that) return Int.LT; return ticks  == that ? Int.EQ : Int.GT;
  }

  public final int hashCode()
  {
    return (int)(ticks ^ (ticks >>> 32));
  }

  public final Int hash()
  {
    return Int.make(ticks);
  }

  public final Int ticks()
  {
    return Int.make(ticks);
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

  public final Duration mult(Float x)
  {
    return make((long)(ticks * x.val));
  }

  public final Duration div(Float x)
  {
    return make((long)(ticks / x.val));
  }

  public final Duration floor(Duration accuracy)
  {
    if (ticks % accuracy.ticks == 0) return this;
    return make(ticks - (ticks % accuracy.ticks));
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public Str toStr()
  {
    if (ticks == 0) return ZeroStr;
    return Str.make(str());
  }

  public void encode(ObjEncoder out)
  {
    out.w(str());
  }

  public String str()
  {
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

  public final Int toMillis()
  {
    return Int.make(ticks/nsPerMilli);
  }

  public final Int toSec()
  {
    return Int.make(ticks/nsPerSec);
  }

  public final Int toMin()
  {
    return Int.make(ticks/nsPerMin);
  }

  public final Int toHour()
  {
    return Int.make(ticks/nsPerHr);
  }

  public final Int toDay()
  {
    return Int.make(ticks/nsPerDay);
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public Str toLocale()
  {
    long ticks = this.ticks;

    // less than 1000ns Xns
    if (ticks < 1000L) return Str.make(ticks + "ns");

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
      return Str.make(s.toString());
    }

    // less than 2sec Xms
    if (ticks < 2L*nsPerSec)   return Str.make(ticks/nsPerMilli + "ms");

    // less than 2min Xsec
    if (ticks < 1L*nsPerMin)   return Str.make(ticks/nsPerSec+ "sec");

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
    return Str.make(s.toString());
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
  public static final Str ZeroStr = Str.make("0ns");
  public static final long nsPerDay   = 86400000000000L;
  public static final long nsPerHr    = 3600000000000L;
  public static final long nsPerMin   = 60000000000L;
  public static final long nsPerSec   = 1000000000L;
  public static final long nsPerMilli = 1000000L;
  private static final Duration boot = now();

  public final long ticks;
  private Str str;

}