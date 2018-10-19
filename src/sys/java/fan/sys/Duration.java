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
      throw ParseErr.make("Duration",  s);
    }
  }

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

  public static long nowTicks()
  {
    return System.nanoTime();
  }

  public static long nowMillis()
  {
    return System.nanoTime() / 1000000L;
  }

  public static Duration boot()
  {
    return Sys.bootDuration;
  }

  public static Duration uptime()
  {
    return new Duration(System.nanoTime() - boot().ticks);
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

  public final long compare(Object obj)
  {
    long that = ((Duration)obj).ticks;
    if (ticks < that) return -1; return ticks  == that ? 0 : +1;
  }

  public final int hashCode()
  {
    return (int)(ticks ^ (ticks >>> 32));
  }

  public final long hash()
  {
    return ticks;
  }

  public final long ticks()
  {
    return ticks;
  }

  public final Type typeof()
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

  public final Duration mult(long x)
  {
    return make(ticks * x);
  }

  public final Duration multFloat(double x)
  {
    return make((long)(ticks * x));
  }

  public final Duration div(long x)
  {
    return make(ticks / x);
  }

  public final Duration divFloat(double x)
  {
    return make((long)(ticks / x));
  }

  public final Duration floor(Duration accuracy)
  {
    if (ticks % accuracy.ticks == 0) return this;
    return make(ticks - (ticks % accuracy.ticks));
  }

  public final Duration min(Duration that)
  {
    return this.ticks <= that.ticks ? this : that;
  }

  public final Duration max(Duration that)
  {
    return this.ticks >= that.ticks ? this : that;
  }

  public final Duration abs()
  {
    if (ticks >= 0) return this;
    return make(-ticks);
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toStr()
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

  public void encode(ObjEncoder out)
  {
    out.w(toStr());
  }

  public String toCode()
  {
    return toStr();
  }

  public final long toMillis()
  {
    return ticks/nsPerMilli;
  }

  public final long toSec()
  {
    return ticks/nsPerSec;
  }

  public final long toMin()
  {
    return ticks/nsPerMin;
  }

  public final long toHour()
  {
    return ticks/nsPerHr;
  }

  public final long toDay()
  {
    return ticks/nsPerDay;
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public String toLocale()
  {
    StringBuilder s = new StringBuilder();
    long ticks = this.ticks;
    Pod pod = Sys.sysPod;
    Env env = Env.cur();
    Locale locale = Locale.cur();

    // handle negatives
    if (ticks < 0)
    {
      s.append((char)'-');
      ticks = -ticks;
    }

    // less than 1000ns Xns
    if (ticks < 1000L) return s.append(ticks).append(env.locale(pod, "nsAbbr", "ns", locale)).toString();

    // less than 2ms X.XXXms
    if (ticks < 2*nsPerMilli)
    {
      long ms = ticks/nsPerMilli;
      long us = (ticks - ms*nsPerMilli)/1000L;
      s.append(ms);
      s.append('.');
      if (us < 100) s.append('0');
      if (us < 10)  s.append('0');
      s.append(us);
      if (s.charAt(s.length()-1) == '0') s.setLength(s.length()-1);
      if (s.charAt(s.length()-1) == '0') s.setLength(s.length()-1);
      s.append(env.locale(pod, "msAbbr", "ms", locale));
      return s.toString();
    }

    // less than 2sec Xms
    if (ticks < 2L*nsPerSec)   return s.append(ticks/nsPerMilli).append(env.locale(pod, "msAbbr", "ms", locale)).toString();

    // less than 2min Xsec
    if (ticks < 1L*nsPerMin)   return s.append(ticks/nsPerSec).append(env.locale(pod, "secAbbr", "sec", locale)).toString();

    // [Xdays] [Xhr] Xmin Xsec
    long days  = ticks/nsPerDay; ticks -= days*nsPerDay;
    long hr  = ticks/nsPerHr;    ticks -= hr*nsPerHr;
    long min = ticks/nsPerMin;   ticks -= min*nsPerMin;
    long sec = ticks/nsPerSec;

    if (days > 0) s.append(days).append(days == 1 ? env.locale(pod, "dayAbbr", "day", locale) : env.locale(pod, "daysAbbr", "days", locale)).append(' ');
    if (hr > 0)   s.append(hr).append(env.locale(pod, "hourAbbr", "hr", locale)).append(' ');
    if (min > 0)  s.append(min).append(env.locale(pod, "minAbbr", "min", locale)).append(' ');
    if (sec > 0)  s.append(sec).append(env.locale(pod, "secAbbr", "sec", locale)).append(' ');
    s.setLength(s.length()-1);
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  public String toIso()
  {
    StringBuilder s = new StringBuilder();
    long ticks = this.ticks;
    if (ticks == 0) return "PT0S";

    if (ticks < 0) s.append('-');
    s.append('P');
    long abs  = Math.abs(ticks);
    long sec  = abs / nsPerSec;
    long frac = abs % nsPerSec;

    // days
    if (sec > secPerDay) { s.append(sec/secPerDay).append('D'); sec = sec % secPerDay; }
    if (sec == 0 && frac == 0) return s.toString();
    s.append('T');

    // hours, minutes
    if (sec > secPerHr)  { s.append(sec/secPerHr).append('H');  sec = sec % secPerHr; }
    if (sec > secPerMin) { s.append(sec/secPerMin).append('M'); sec = sec % secPerMin; }
    if (sec == 0 && frac == 0) return s.toString();

    // seconds and fractional seconds
    s.append(sec);
    if (frac != 0)
    {
      s.append('.');
      for (int i=10; i<=100000000; i*=10) if (frac < i) s.append('0');
      s.append(frac);
      while (s.charAt(s.length()-1) == '0') s.setLength(s.length()-1);
    }
    s.append('S');
    return s.toString();
  }

  public static Duration fromIso(String s) { return fromIso(s, true); }
  public static Duration fromIso(String s, boolean checked)
  {
    try
    {
      long ticks = 0;
      boolean neg = false;
      IsoParser p = new IsoParser(s);

      // check for negative
      if (p.cur == '-') { neg = true; p.consume(); }
      else if (p.cur == '+') { p.consume(); }

      // next char must be P
      p.consume('P');
      if (p.cur == -1) throw new Exception();

      // D
      int num = 0;
      if (p.cur != 'T')
      {
        num = p.num();
        p.consume('D');
        ticks += num * nsPerDay;
        if (p.cur == -1) return new Duration(ticks);
      }

      // next char must be T
      p.consume('T');
      if (p.cur == -1) throw new Exception();
      num = p.num();

      // H
      if (num >= 0 && p.cur == 'H')
      {
        p.consume();
        ticks += num * nsPerHr;
        num = p.num();
      }

      // M
      if (num >= 0 && p.cur == 'M')
      {
        p.consume();
        ticks += num * nsPerMin;
        num = p.num();
      }

      // S
      if (num >= 0 && p.cur == 'S' || p.cur == '.')
      {
        ticks += num * nsPerSec;
        if (p.cur == '.') { p.consume(); ticks += p.frac(); }
        p.consume('S');
      }

      // verify we parsed everything
      if (p.cur != -1) throw new Exception();

      // negate if necessary and return result
      if (neg) ticks = -ticks;
      return new Duration(ticks);
    }
    catch(Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("ISO 8601 Duration",  s);
    }
  }

  static class IsoParser
  {
    IsoParser(String s)
    {
      this.s = s;
      this.cur = s.charAt(0);
    }

    int num()
    {
      if (!curIsDigit && cur != -1 && cur != '.')
        throw new IllegalStateException();
      int num = 0;
      while(curIsDigit)
      {
        num = num*10 + digit();
        consume();
      }
      return num;
    }

    int frac()
    {
      // get up to nine decimal places as milliseconds within a fraction
      int ticks = 0;
      for (int i=100000000; i>=0; i/=10)
      {
        if (!curIsDigit) break;
        ticks += digit() * i;
        consume();
      }
      return ticks;
    }

    int digit() { return cur - '0'; }

    void consume(int ch)
    {
      if (cur != ch) throw new IllegalStateException();
      consume();
    }

    void consume()
    {
      off++;
      if (off < s.length())
      {
        cur = s.charAt(off);
        curIsDigit = '0' <= cur && cur <= '9';
      }
      else
      {
        cur = -1;
        curIsDigit = false;
      }
    }

    String s;
    int off, cur;
    boolean curIsDigit;
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
  public static final long secPerDay  = 86400L;
  public static final long secPerHr   = 3600L;
  public static final long secPerMin  = 60L;

  public static final Duration defVal    = Zero;
  public static final Duration minVal    = make(FanInt.minVal);
  public static final Duration maxVal    = make(FanInt.maxVal);
  public static final Duration oneDay    = make(nsPerDay);
  public static final Duration oneSec    = make(nsPerSec);
  public static final Duration oneMin    = make(nsPerMin);
  public static final Duration negOneDay = make(-nsPerDay);

  public final long ticks;
  private String str;

}