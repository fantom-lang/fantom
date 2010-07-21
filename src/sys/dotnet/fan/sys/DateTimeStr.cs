//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 10  Brian Frank  Creation
//

using System;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// DateTimeStr is used to format/parse DateTime, Date, and Time
  /// using the standard pattern syntax.
  /// </summary>

  internal class DateTimeStr
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    internal DateTimeStr(string pattern, Locale locale, DateTime dt)
    {
      this.pattern  = pattern;
      this.m_locale = locale;
      this.year     = dt.getYear();
      this.mon      = dt.month();
      this.day      = dt.getDay();
      this.hour     = dt.getHour();
      this.min      = dt.getMin();
      this.sec      = dt.getSec();
      this.ns       = dt.getNanoSec();
      this.weekday  = dt.weekday();
      this.tz       = dt.tz();
      this.dst      = dt.dst();
    }

    internal DateTimeStr(string pattern, Locale locale, Date d)
    {
      this.pattern  = pattern;
      this.m_locale = locale;
      this.year     = d.getYear();
      this.mon      = d.month();
      this.day      = d.getDay();
      try { this.weekday = d.weekday(); } catch (Exception) {}
    }

    internal DateTimeStr(string pattern, Locale locale, Time t)
    {
      this.pattern  = pattern;
      this.m_locale = locale;
      this.hour     = t.getHour();
      this.min      = t.getMin();
      this.sec      = t.getSec();
      this.ns       = t.getNanoSec();
    }

    internal DateTimeStr(string pattern, Locale locale)
    {
      this.pattern  = pattern;
      this.m_locale = locale;
    }

  //////////////////////////////////////////////////////////////////////////
  // Formatting
  //////////////////////////////////////////////////////////////////////////

    public string format()
    {
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
          case 'Y':
            int y = this.year;
            switch (n)
            {
              case 2:  y %= 100; if (y < 10) s.Append('0'); s.Append(y); break;
              case 4:  s.Append(y); break;
              default: invalidNum = true; break;
            }
            break;

          case 'M':
            switch (n)
            {
              case 4:
                s.Append(mon.full(locale()));
                break;
              case 3:
                s.Append(mon.abbr(locale()));
                break;
              case 2:  if (mon.ordinal()+1 < 10L) s.Append('0'); s.Append(mon.ordinal()+1); break;
              case 1:  s.Append(mon.ordinal()+1); break;
              default: invalidNum = true; break;
            }
            break;

          case 'D':
            switch (n)
            {
              case 3:  s.Append(day).Append(daySuffix(day)); break;
              case 2:  if (day < 10) s.Append('0'); s.Append(day); break;
              case 1:  s.Append(day); break;
              default: invalidNum = true; break;
            }
            break;

          case 'W':
            switch (n)
            {
              case 4:
                s.Append(weekday.full(locale()));
                break;
              case 3:
                s.Append(weekday.abbr(locale()));
                break;
              default: invalidNum = true; break;
            }
            break;

          case 'h':
          case 'k':
            int h = this.hour;
            if (c == 'k')
            {
              if (h == 0) h = 12;
              else if (h > 12) h -= 12;
            }
            switch (n)
            {
              case 2:  if (h < 10) s.Append('0'); s.Append(h); break;
              case 1:  s.Append(h); break;
              default: invalidNum = true; break;
            }
            break;

          case 'm':
            switch (n)
            {
              case 2:  if (min < 10) s.Append('0'); s.Append(min); break;
              case 1:  s.Append(min); break;
              default: invalidNum = true; break;
            }
            break;

          case 's':
            switch (n)
            {
              case 2:  if (sec < 10) s.Append('0'); s.Append(sec); break;
              case 1:  s.Append(sec); break;
              default: invalidNum = true; break;
            }
            break;

          case 'S':
            if (sec != 0 || ns != 0)
            {
              switch (n)
              {
                case 2:  if (sec < 10) s.Append('0'); s.Append(sec); break;
                case 1:  s.Append(sec); break;
                default: invalidNum = true; break;
              }
            }
            break;

          case 'a':
            switch (n)
            {
              case 1:  s.Append(hour < 12 ? "a"  : "p"); break;
              case 2:  s.Append(hour < 12 ? "am" : "pm"); break;
              default: invalidNum = true; break;
            }
            break;

          case 'A':
            switch (n)
            {
              case 1:  s.Append(hour < 12 ? "A"  : "P"); break;
              case 2:  s.Append(hour < 12 ? "AM" : "PM"); break;
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
            int frac = ns;
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

          case 'z':
            TimeZone.Rule rule = tz.rule(year);
            switch (n)
            {
              case 1:
                int offset = rule.offset;
                if (dst) offset += rule.dstOffset;
                if (offset == 0) { s.Append('Z'); break; }
                if (offset < 0) { s.Append('-'); offset = -offset; }
                else { s.Append('+'); }
                int zh = offset / 3600;
                int zm = (offset % 3600) / 60;
                if (zh < 10) s.Append('0'); s.Append(zh).Append(':');
                if (zm < 10) s.Append('0'); s.Append(zm);
                break;
              case 3:
                s.Append(dst ? rule.dstAbbr : rule.stdAbbr);
                break;
              case 4:
                s.Append(tz.name());
                break;
              default:
                invalidNum = true;
                break;
            }
            break;

          default:
            if (FanInt.isAlpha(c))
              throw ArgErr.make("Invalid pattern: unsupported char '" + (char)c + "'").val;

             // check for symbol skip
            if (i+1 < len)
            {
              int next = pattern[i+1];

              // don't display symbol between ss.FFF if fractions is zero
              if (next  == 'F' && ns == 0) break;

              // don't display symbol between mm:SS if secs is zero
              if (next == 'S' && sec == 0 && ns == 0) break;
            }

            s.Append((char)c);
            break;
        }

        // if invalid number of characters
        if (invalidNum)
          throw ArgErr.make("Invalid pattern: unsupported num of '" + (char)c + "' (x" + n + ")").val;
      }

      return s.ToString();
    }

    private static string daySuffix(int day)
    {
      // eventually need localization
      switch (day)
      {
        case 1: return "st";
        case 2: return "nd";
        case 3: return "rd";
        default: return "th";
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Parse
  //////////////////////////////////////////////////////////////////////////

    internal DateTime parseDateTime(string s, TimeZone defTz, bool check)
    {
      try
      {
        // parse into fields
        tzOffset = System.Int32.MaxValue;
        parse(s);

        // now figure out what timezone to use
        TimeZone.Rule defRule = defTz.rule(year);
        if (tzName != null)
        {
          // use defTz if tzName was specified and matches any variations of defTz
          if (tzName == defTz.name() ||
              tzName == defRule.stdAbbr ||
              tzName == defRule.dstAbbr)
          {
            tz = defTz;
          }

          // try to map tzName to TimeZone, use defTz as fallback
          else
          {
            tz = TimeZone.fromStr(tzName, false);
            if (tz == null) tz = defTz;
          }
        }

        // if tzOffset was specified...
        else if (tzOffset != System.Int32.MaxValue)
        {
          // figure out what expected offset was for defTz
          int time = hour*3600 + min*60 + sec;
          int defOffset = defRule.offset + TimeZone.dstOffset(defRule, year, (int)mon.ordinal(), day, time);

          // if specified offset matches expected offset for defTz then
          // use defTz, otherwise use a vanilla GMT+/- timezone
          if (tzOffset == defOffset)
            tz = defTz;
          else
            tz = TimeZone.fromGmtOffset(tzOffset);
        }

        // no tzName or tzOffset specified, use defTz
        else tz = defTz;

        // construct DateTime
        return new DateTime(year, (int)mon.ordinal(), day, hour, min, sec, ns, tzOffset, tz);
      }
      catch (Exception) {}
      if (check) throw ParseErr.make("DateTime", s).val;
      return null;
    }

    internal Date parseDate(string s, bool check)
    {
      try
      {
        parse(s);
        return new Date(year, (int)mon.ordinal(), day);
      }
      catch (Exception) {}
      if (check) throw ParseErr.make("Date", s).val;
      return null;
    }

    internal Time parseTime(string s, bool check)
    {
      try
      {
        parse(s);
        return new Time(hour, min, sec, ns);
      }
      catch (Exception) {}
      if (check) throw ParseErr.make("Time", s).val;
      return null;
    }

    private void parse(string s)
    {
      this.str = s;
      this.pos = 0;
      int len = pattern.Length;
      bool skippedLast = false;
      for (int i=0; i<len; ++i)
      {
        // character
        int c = pattern[i];

        // character count
        int n = 1;
        while (i+1<len && pattern[i+1] == c) { ++i; ++n; }

        // switch
        switch (c)
        {
          case 'Y':
            year = parseInt(n);
            if (year < 30) year += 2000;
            else if (year < 100) year += 1900;
            break;

          case 'M':
            switch (n)
            {
              case 4:  mon = parseMon(); break;
              case 3:  mon = parseMon(); break;
              default: mon = Month.array[parseInt(n)-1]; break;
            }
            break;

          case 'D':
            if (n != 3) day = parseInt(n);
            else
            {
              // suffix like st, nd, th
              day = parseInt(1);
              skipWord();
            }
            break;

          case 'h':
          case 'k':
            hour = parseInt(n);
            break;

          case 'm':
            min = parseInt(n);
            break;

          case 's':
            sec = parseInt(n);
            break;

          case 'S':
            if (!skippedLast) sec = parseInt(n);
            break;

          case 'a':
          case 'A':
            int amPm = str[pos]; pos += n;
            if (amPm == 'P' || amPm == 'p')
            {
              if (hour < 12) hour += 12;
            }
            else
            {
              if (hour == 12) hour = 0;
            }
            break;

          case 'W':
            skipWord();
            break;


          case 'f':
          case 'F':
            if (c == 'F' && skippedLast) break;
            ns = 0;
            int tenth = 100000000;
            while (true)
            {
              int digit = parseOptDigit();
              if (digit < 0) break;
              ns += tenth * digit;
              tenth /= 10;
            }
            break;

          case 'z':
            switch (n)
            {
              case 1:  parseTzOffset(); break;
              default: parseTzName(); break;
            }
            break;

          case '\'':
            while (true)
            {
              int expected = pattern[++i];
              if (expected == '\'') break;
              int actual = str[pos++];
              if (actual != expected) throw new Exception();
            }
            break;

          default:
            int match = pos+1 < str.Length ? str[pos++] : 0;

            // handle skipped symbols
            if (i+1 < pattern.Length)
            {
              int next = pattern[i+1];
              if (next == 'F' || next == 'S')
              {
                if (match != c) { skippedLast = true;  break; }
              }
            }

            skippedLast = false;
            if (match != c) throw new Exception();
            break;
        }

      }
    }

    private int parseInt(int n)
    {
      // parse n digits
      int num = 0;
      for (int i=0; i<n; ++i) num = num*10 + parseReqDigit();

      // one char like 'k' really implies one or two digits
      if (n == 1)
      {
        int digit = parseOptDigit();
        if (digit >= 0) num = num*10 + digit;
      }

      return num;
    }

    private int parseReqDigit()
    {
      int ch = str[pos++];
      if ('0' <= ch && ch <= '9') return ch - '0';
      throw new Exception();
    }

    private int parseOptDigit()
    {
      if (pos < str.Length)
      {
        int ch = str[pos];
        if ('0' <= ch && ch <= '9') { pos++; return ch - '0'; }
      }
      return -1;
    }

    private Month parseMon()
    {
      StringBuilder s = new StringBuilder();
      while (pos < str.Length)
      {
        int ch = str[pos];
        if ('a' <= ch && ch <= 'z') { s.Append((char)ch); pos++; continue; }
        if ('A' <= ch && ch <= 'Z') { s.Append((char)FanInt.lower(ch)); pos++; continue; }
        break;
      }
      Month m = locale().monthByName(s.ToString());
      if (m == null) throw new Exception();
      return m;
    }

    private void parseTzOffset()
    {
      int ch = str[pos++];
      bool neg;
      switch (ch)
      {
        case '-': neg = true; break;
        case '+': neg = false; break;
        case 'Z': tzOffset = 0; return;
        default: throw new Exception();
      }

      int hr = parseInt(1);
      int min = 0;
      if (pos < str.Length && str[pos] == ':')
      {
        pos++;
        min = parseInt(1);
      }
      tzOffset = hr*3600 + min*60;
      if (neg) tzOffset = -tzOffset;
    }

    private void parseTzName()
    {
      StringBuilder s = new StringBuilder();
      while (pos < str.Length)
      {
        int ch = str[pos];
        if (('a' <= ch && ch <= 'z') ||
            ('A' <= ch && ch <= 'Z') ||
            ('0' <= ch && ch <= '9') ||
            ch == '+' || ch == '-' || ch == '_')
        {
          s.Append((char)ch);
          pos++;
        }
        else break;
      }
      tzName = s.ToString();
    }

    private void skipWord()
    {
      while (pos < str.Length)
      {
        int ch = str[pos];
        if (('a' <= ch && ch <= 'z') || ('A' <= ch && ch <= 'Z'))
          pos++;
        else
          break;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    private Locale locale()
    {
      if (m_locale == null) m_locale = Locale.cur();
      return m_locale;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    string pattern;
    int year;
    Month mon;
    int day;
    int hour;
    int min;
    int sec;
    int ns;
    Weekday weekday;
    TimeZone tz;
    string tzName;
    int tzOffset;
    bool dst;
    Locale m_locale;
    string str;  // when parsing
    int pos;     // index in str for parse
  }
}