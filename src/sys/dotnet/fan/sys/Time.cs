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
  /// Time represents a time of day independent of a specific
  /// date or timezone.
  /// </summary>
  public sealed class Time : FanObj
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

    internal Time(int hour, int min, int sec, int ns)
    {
      if (hour < 0 || hour > 23)     throw ArgErr.make("hour " + hour).val;
      if (min < 0 || min > 59)       throw ArgErr.make("min " + min).val;
      if (sec < 0 || sec > 59)       throw ArgErr.make("sec " + sec).val;
      if (ns < 0 || ns > 999999999)  throw ArgErr.make("ns " + ns).val;

      this.m_hour = (byte)hour;
      this.m_min  = (byte)min;
      this.m_sec  = (byte)sec;
      this.m_ns   = ns;
    }

    public static Time fromStr(string s) { return fromStr(s, true); }
    public static Time fromStr(string s, bool check)
    {
      try
      {
        // hh:mm:ss
        int hour  = num(s, 0)*10  + num(s, 1);
        int min   = num(s, 3)*10  + num(s, 4);
        int sec   = num(s, 6)*10  + num(s, 7);

        // check separator symbols
        if (s[2] != ':' || s[5] != ':')
          throw new System.Exception();

        // optional .FFFFFFFFF
        int i = 8;
        int ns = 0;
        int tenth = 100000000;
        int len = s.Length;
        if (i < len && s[i] == '.')
        {
          ++i;
          while (i < len)
          {
            int c = s[i];
            if (c < '0' || c > '9') break;
            ns += (c - '0') * tenth;
            tenth /= 10;
            ++i;
          }
        }

        // verify everything has been parsed
        if (i < s.Length) throw new System.Exception();

        return new Time(hour, min, sec, ns);
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Time", s).val;
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
      if (obj is Time)
      {
        Time x = (Time)obj;
        return m_hour == x.m_hour && m_min == x.m_min && m_sec == x.m_sec && m_ns == x.m_ns;
      }
      return false;
    }

    public override long compare(object obj)
    {
      Time x = (Time)obj;
      if (m_hour == x.m_hour)
      {
        if (m_min == x.m_min)
        {
          if (m_sec == x.m_sec)
          {
            if (m_ns == x.m_ns) return 0;
            return m_ns < x.m_ns ? -1 : +1;
          }
          return m_sec < x.m_sec ? -1 : +1;
        }
        return m_min < x.m_min ? -1 : +1;
      }
      return m_hour < x.m_hour ? -1 : +1;
    }

    public override int GetHashCode()
    {
      return (m_hour << 24) ^ (m_min << 20) ^ (m_sec << 16) ^ m_ns;
    }

    public override long hash()
    {
      return (m_hour << 24) ^ (m_min << 20) ^ (m_sec << 16) ^ m_ns;
    }

    public override string toStr()
    {
      return toLocale("hh:mm:ss.FFFFFFFFF");
    }

    public override Type type()
    {
      return Sys.TimeType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public long hour() { return m_hour; }
    public int getHour() { return m_hour; }

    public long min() { return m_min; }
    public int getMin() { return m_min; }

    public long sec() { return m_sec; }
    public int getSec() { return m_sec; }

    public long nanoSec() { return m_ns; }
    public int getNanoSec() { return m_ns; }

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
        pattern = locale.get("sys", m_localeKey, "hh:mm:ss");
      }

      // process pattern
      StringBuilder s = new StringBuilder();
      int len = pattern.Length;
      for (int i=0; i<len; ++i)
      {
        // character
        int c = pattern[i];

        // literals
        if (c == '\'')
        {
          while (true)
          {
            ++i;
            if (i >= len) throw ArgErr.make("Invalid pattern: unterminated literal").val;
            c = pattern[i];
            if (c == '\'') break;
            s.Append((char)c);
          }
          continue;
        }

        // character count
        int n = 1;
        while (i+1<len && pattern[i+1] == c) { ++i; ++n; }

        // switch
        bool invalidNum = false;
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
              case 2:  if (hour < 10) s.Append('0'); s.Append(hour); break;
              case 1:  s.Append(hour); break;
              default: invalidNum = true; break;
            }
            break;

          case 'm':
            int min = getMin();
            switch (n)
            {
              case 2:  if (min < 10) s.Append('0'); s.Append(min); break;
              case 1:  s.Append(min); break;
              default: invalidNum = true; break;
            }
            break;

          case 's':
            int sec = getSec();
            switch (n)
            {
              case 2:  if (sec < 10) s.Append('0'); s.Append(sec); break;
              case 1:  s.Append(sec); break;
              default: invalidNum = true; break;
            }
            break;

          case 'a':
            switch (n)
            {
              case 1:  s.Append(getHour() < 12 ? "AM" : "PM"); break;
              default: invalidNum = true; break;
            }
            break;

          case 'f':
          case 'F':
            int req = 0, opt = 0; // required, optional
            if (c == 'F') opt = n;
            else
            {
              req = n;
              while (i+1<len && pattern[i+1] == 'F') { ++i; ++opt; }
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
              s.Append(frac/tenth);
              frac %= tenth;
              tenth /= 10;
            }
            break;

          default:
            if (FanInt.isAlpha(c))
              throw ArgErr.make("Invalid pattern: unsupported char '" + (char)c + "'").val;

            // don't display symbol between ss.FFF if fractions is zero
            if (i+1<len && pattern[i+1] == 'F' && getNanoSec() == 0)
              break;

            s.Append((char)c);
            break;
        }

        // if invalid number of characters
        if (invalidNum)
          throw ArgErr.make("Invalid pattern: unsupported num '" + (char)c + "' (x" + n + ")").val;
      }

      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // ISO 8601
  //////////////////////////////////////////////////////////////////////////

    public string toIso() { return toStr(); }

    public static Time fromIso(string s) { return fromStr(s, true); }
    public static Time fromIso(string s, bool check) { return fromStr(s, check); }

  //////////////////////////////////////////////////////////////////////////
  // Misc
  //////////////////////////////////////////////////////////////////////////

    public static Time fromDuration(Duration d)
    {
      long ticks = d.m_ticks;
      if (ticks == 0) return m_defVal;

      if (ticks < 0 || ticks > Duration.nsPerDay )
        throw ArgErr.make("Duration out of range: " + d).val;

      int hour = (int)(ticks / Duration.nsPerHr);  ticks %= Duration.nsPerHr;
      int min  = (int)(ticks / Duration.nsPerMin); ticks %= Duration.nsPerMin;
      int sec  = (int)(ticks / Duration.nsPerSec); ticks %= Duration.nsPerSec;
      int ns   = (int)ticks;

      return new Time(hour, min, sec, ns);
    }

    public Duration toDuration()
    {
      return Duration.make(m_hour*Duration.nsPerHr +
                           m_min*Duration.nsPerMin +
                           m_sec*Duration.nsPerSec +
                           m_ns);
    }

    public DateTime toDateTime(Date d) { return DateTime.makeDT(d, this); }
    public DateTime toDateTime(Date d, TimeZone tz) { return DateTime.makeDT(d, this, tz); }

    public string toCode()
    {
      if (Equals(m_defVal)) return "Time.defVal";
      return "Time(\"" + ToString() + "\")";
    }

    public bool isMidnight()
    {
      return this.Equals(m_defVal);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static readonly string m_localeKey = "time";

    public static readonly Time m_defVal = new Time(0, 0, 0, 0);

    internal readonly byte m_hour;
    internal readonly byte m_min;
    internal readonly byte m_sec;
    internal readonly int m_ns;

  }
}