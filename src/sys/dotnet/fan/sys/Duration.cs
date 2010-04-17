//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 06  Andy Frank  Creation
//

using System;
using System.Text;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Duration
  /// </summary>
  public sealed class Duration : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Duration fromStr(string s) { return fromStr(s, true); }
    public static Duration fromStr(string s, bool check)
    {
      //   ns:   nanoseconds  (x 1)
      //   ms:   milliseconds (x 1,000,000)
      //   sec:  seconds      (x 1,000,000,000)
      //   min:  minutes      (x 60,000,000,000)
      //   hr:   hours        (x 3,600,000,000,000)
      //   day:  days         (x 86,400,000,000,000)
      try
      {
        int len = s.Length;
        int x1 = s[len-1];
        int x2 = s[len-2];
        int x3 = s[len-3];
        bool dot = s.IndexOf('.') > 0;

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

        s = s.Substring(0, len-suffixLen);
        if (dot)
          return make((long)(System.Double.Parse(s)*(double)mult));
        else
          return make(Int64.Parse(s)*mult);
      }
      catch (Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Duration",  s).val;
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
      // TODO - need to be like System.nanoTime()
      /*
      Brian: you want to find whatever wraps getTickCount
      (or call the win32 function directly) 10:40PM Mon

      Brian: there is also QueryPerformanceCounter, you
      might want to check what System.nanoTime does for
      win32 in the HotSpot cod
      */

      return new Duration(System.DateTime.Now.Ticks * 100);
    }

    public static long nowTicks()
    {
      return System.DateTime.Now.Ticks * 100;
    }

    public static Duration boot()
    {
      return m_boot;
    }

    public static Duration uptime()
    {
      return new Duration(System.DateTime.Now.Ticks * 100 - m_boot.m_ticks);
    }

    private Duration(long ticks)
    {
      this.m_ticks = ticks;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed bool Equals(object obj)
    {
      if (obj is Duration)
        return m_ticks == ((Duration)obj).m_ticks;
      else
        return false;
    }

    public override sealed long compare(object obj)
    {
      long that = ((Duration)obj).m_ticks;
      if (m_ticks < that) return -1; return m_ticks  == that ? 0 : +1;
    }

    public override sealed int GetHashCode()
    {
      return (int)(m_ticks ^ (m_ticks >> 32));
    }

    public override sealed long hash()
    {
      return m_ticks;
    }

    public long ticks()
    {
      return m_ticks;
    }

    public override sealed Type @typeof()
    {
      return Sys.DurationType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Duration negate()
    {
      return make(-m_ticks);
    }

    public Duration plus(Duration x)
    {
      return make(m_ticks + x.m_ticks);
    }

    public Duration minus(Duration x)
    {
      return make(m_ticks - x.m_ticks);
    }

    public Duration mult(double x)
    {
      return make((long)(m_ticks * x));
    }

    public Duration div(double x)
    {
      return make((long)(m_ticks / x));
    }

    public Duration floor(Duration accuracy)
    {
      if (m_ticks % accuracy.m_ticks == 0) return this;
      return make(m_ticks - (m_ticks % accuracy.m_ticks));
    }

    public Duration abs()
    {
      if (m_ticks >= 0) return this;
      return make(-m_ticks);
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public override string toStr()
    {
      if (m_ticks == 0) return "0ns";

      // if clean millisecond boundary
      long ns = m_ticks;
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

    public string toCode()
    {
      return toStr();
    }

    public void encode(ObjEncoder @out)
    {
      @out.w(toStr());
    }

    public long toMillis()
    {
      return m_ticks/nsPerMilli;
    }

    public long toSec()
    {
      return m_ticks/nsPerSec;
    }

    public long toMin()
    {
      return m_ticks/nsPerMin;
    }

    public long toHour()
    {
      return m_ticks/nsPerHr;
    }

    public long toDay()
    {
      return m_ticks/nsPerDay;
    }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public string toLocale()
    {
      long ticks = this.m_ticks;
      StringBuilder s;

      // less than 1000ns Xns
      if (ticks < 1000L) return ticks + "ns";

      // less than 2ms X.XXXms
      if (ticks < 2*nsPerMilli)
      {
        s = new StringBuilder();
        long ms = ticks/nsPerMilli;
        long us = (ticks - ms*nsPerMilli)/1000L;
        s.Append(ms);
        s.Append('.');
        if (us < 100) s.Append('0');
        if (us < 10)  s.Append('0');
        s.Append(us);
        if (s[s.Length-1] == '0') s.Length = s.Length-1;
        if (s[s.Length-1] == '0') s.Length = s.Length-1;
        s.Append("ms");
        return s.ToString();
      }

      // less than 2sec Xms
      if (ticks < 2L*nsPerSec) return (ticks/nsPerMilli) + "ms";

      // less than 2min Xsec
      if (ticks < 1L*nsPerMin) return (ticks/nsPerSec) + "sec";

      // [Xdays] [Xhr] Xmin Xsec
      long days  = ticks/nsPerDay; ticks -= days*nsPerDay;
      long hr  = ticks/nsPerHr;    ticks -= hr*nsPerHr;
      long min = ticks/nsPerMin;   ticks -= min*nsPerMin;
      long sec = ticks/nsPerSec;

      s = new StringBuilder();
      if (days > 0) s.Append(days).Append(days == 1 ? "day " : "days ");
      if (hr > 0)   s.Append(hr).Append("hr ");
      if (min > 0)  s.Append(min).Append("min ");
      if (sec > 0)  s.Append(sec).Append("sec ");
      s.Length = s.Length - 1;
      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // ISO 8601
  //////////////////////////////////////////////////////////////////////////

    public string toIso()
    {
      StringBuilder s = new StringBuilder();
      long ticks = this.m_ticks;
      if (ticks == 0) return "PT0S";

      if (ticks < 0) s.Append('-');
      s.Append('P');
      long abs  = ticks < 0 ? -ticks : ticks;
      long sec  = abs / nsPerSec;
      long frac = abs % nsPerSec;

      // days
      if (sec > secPerDay) { s.Append(sec/secPerDay).Append('D'); sec = sec % secPerDay; }
      if (sec == 0 && frac == 0) return s.ToString();
      s.Append('T');

      // hours, minutes
      if (sec > secPerHr)  { s.Append(sec/secPerHr).Append('H');  sec = sec % secPerHr; }
      if (sec > secPerMin) { s.Append(sec/secPerMin).Append('M'); sec = sec % secPerMin; }
      if (sec == 0 && frac == 0) return s.ToString();

      // seconds and fractional seconds
      s.Append(sec);
      if (frac != 0)
      {
        s.Append('.');
        for (int i=10; i<=100000000; i*=10) if (frac < i) s.Append('0');
        s.Append(frac);
        while (s[s.Length-1] == '0') s.Length = s.Length -1;
      }
      s.Append('S');
      return s.ToString();
    }

    public static Duration fromIso(string s) { return fromIso(s, true); }
    public static Duration fromIso(string s, bool check)
    {
      try
      {
        long ticks = 0;
        bool neg = false;
        IsoParser p = new IsoParser(s);

        // check for negative
        if (p.cur == '-') { neg = true; p.consume(); }
        else if (p.cur == '+') { p.consume(); }

        // next char must be P
        p.consume('P');
        if (p.cur == -1) throw new System.Exception();

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
        if (p.cur == -1) throw new System.Exception();
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
        if (p.cur != -1) throw new System.Exception();

        // negate if necessary and return result
        if (neg) ticks = -ticks;
        return new Duration(ticks);
      }
      catch(System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("ISO 8601 Duration", s).val;
      }
    }

    class IsoParser
    {
      internal IsoParser(string s)
      {
        this.s = s;
        this.cur = s[0];
      }

      internal int num()
      {
        if (!curIsDigit && cur != -1 && cur != '.')
          throw new System.Exception();
        int num = 0;
        while(curIsDigit)
        {
          num = num*10 + digit();
          consume();
        }
        return num;
      }

      internal int frac()
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

      internal void consume(int ch)
      {
        if (cur != ch) throw new System.Exception();
        consume();
      }

      internal void consume()
      {
        off++;
        if (off < s.Length)
        {
          cur = s[off];
          curIsDigit = '0' <= cur && cur <= '9';
        }
        else
        {
          cur = -1;
          curIsDigit = false;
        }
      }

      internal String s;
      internal int off, cur;
      internal bool curIsDigit;
    }

  //////////////////////////////////////////////////////////////////////////
  // C#
  //////////////////////////////////////////////////////////////////////////

    public long sec()
    {
      return m_ticks/1000000000L;
    }

    public long millis()
    {
      return m_ticks/1000000L;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Duration Zero = new Duration(0);
    public const long nsPerDay   = 86400000000000L;
    public const long nsPerHr    = 3600000000000L;
    public const long nsPerMin   = 60000000000L;
    public const long nsPerSec   = 1000000000L;
    public const long nsPerMilli = 1000000L;
    public const long secPerDay  = 86400L;
    public const long secPerHr   = 3600L;
    public const long secPerMin  = 60L;
    static readonly Duration m_boot = now();

    public static readonly Duration m_defVal    = Zero;
    public static readonly Duration m_minVal    = make(FanInt.m_minVal);
    public static readonly Duration m_maxVal    = make(FanInt.m_maxVal);
    public static readonly Duration m_oneSec    = make(nsPerSec);
    public static readonly Duration m_oneMin    = make(nsPerMin);
    public static readonly Duration m_oneDay    = make(nsPerDay);
    public static readonly Duration m_negOneDay = make(-nsPerDay);

    public readonly long m_ticks;

  }
}