//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 10  Brian Frank  Creation
//
package fan.sys;

/**
 * DateTimeStr is used to format/parse DateTime, Date, and Time
 * using the standard pattern syntax.
 */
class DateTimeStr
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  DateTimeStr(String pattern, Locale locale, DateTime dt)
  {
    this.pattern = pattern;
    this.locale  = locale;
    this.val     = dt;
    this.year    = dt.getYear();
    this.mon     = dt.month();
    this.day     = dt.getDay();
    this.hour    = dt.getHour();
    this.min     = dt.getMin();
    this.sec     = dt.getSec();
    this.ns      = dt.getNanoSec();
    this.weekday = dt.weekday();
    this.tz      = dt.tz();
    this.dst     = dt.dst();
  }

  DateTimeStr(String pattern, Locale locale, Date d)
  {
    this.pattern = pattern;
    this.locale  = locale;
    this.val     = d;
    this.year    = d.getYear();
    this.mon     = d.month();
    this.day     = d.getDay();
    try { this.weekday = d.weekday(); } catch (Exception e) {}
  }

  DateTimeStr(String pattern, Locale locale, Time t)
  {
    this.pattern = pattern;
    this.locale  = locale;
    this.val     = t;
    this.hour    = t.getHour();
    this.min     = t.getMin();
    this.sec     = t.getSec();
    this.ns      = t.getNanoSec();
  }

  DateTimeStr(String pattern, Locale locale)
  {
    this.pattern = pattern;
    this.locale  = locale;
  }

//////////////////////////////////////////////////////////////////////////
// Formatting
//////////////////////////////////////////////////////////////////////////

  public String format()
  {
    StringBuilder s = new StringBuilder();
    int len = pattern.length();
    for (int i=0; i<len; ++i)
    {
      // character
      int c = pattern.charAt(i);

      // literals
      if (c == '\'')
      {
        int numLiterals = 0;
        while (true)
        {
          ++i;
          if (i >= len) throw ArgErr.make("Invalid pattern: unterminated literal");
          c = pattern.charAt(i);
          if (c == '\'') break;
          s.append((char)c);
          numLiterals++;
        }
        if (numLiterals == 0) s.append((char)'\'');
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
          int y = this.year;
          switch (n)
          {
            case 2:  y %= 100; if (y < 10) s.append('0');
            case 4:  s.append(y); break;
            default: invalidNum = true;
          }
          break;

        case 'M':
          if (mon == null) throw ArgErr.make("Month not available");
          switch (n)
          {
            case 4:
              s.append(mon.full(locale()));
              break;
            case 3:
              s.append(mon.abbr(locale()));
              break;
            case 2:  if (mon.ordinal()+1 < 10L) s.append('0');
            case 1:  s.append(mon.ordinal()+1); break;
            default: invalidNum = true;
          }
          break;

        case 'D':
          switch (n)
          {
            case 3:  s.append(day).append(daySuffix(day)); break;
            case 2:  if (day < 10) s.append('0');
            case 1:  s.append(day); break;
            default: invalidNum = true;
          }
          break;

        case 'W':
          if (weekday == null) throw ArgErr.make("Weekday not available");
          switch (n)
          {
            case 4:
              s.append(weekday.full(locale()));
              break;
            case 3:
              s.append(weekday.abbr(locale()));
              break;
            default: invalidNum = true;
          }
          break;

        case 'V':
          int woy = weekOfYear();
          if (woy < 1) throw ArgErr.make("Week of year not available");
          switch (n)
          {
            case 3:  s.append(woy).append(daySuffix(woy)); break;
            case 2:  if (woy < 10) s.append('0');
            case 1:  s.append(woy); break;
            default: invalidNum = true;
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
            case 2:  if (h < 10) s.append('0');
            case 1:  s.append(h); break;
            default: invalidNum = true;
          }
          break;

        case 'm':
          switch (n)
          {
            case 2:  if (min < 10) s.append('0');
            case 1:  s.append(min); break;
            default: invalidNum = true;
          }
          break;

        case 's':
          switch (n)
          {
            case 2:  if (sec < 10) s.append('0');
            case 1:  s.append(sec); break;
            default: invalidNum = true;
          }
          break;

        case 'S':
          if (sec != 0 || ns != 0)
          {
            switch (n)
            {
              case 2:  if (sec < 10) s.append('0');
              case 1:  s.append(sec); break;
              default: invalidNum = true;
            }
          }
          break;

        case 'a':
          switch (n)
          {
            case 1:  s.append(hour < 12 ? "a"  : "p"); break;
            case 2:  s.append(hour < 12 ? "am" : "pm"); break;
            default: invalidNum = true;
          }
          break;

        case 'A':
          switch (n)
          {
            case 1:  s.append(hour < 12 ? "A"  : "P"); break;
            case 2:  s.append(hour < 12 ? "AM" : "PM"); break;
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
          int frac = ns;
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

        case 'z':
          if (tz == null) throw new IllegalStateException("Format cannot contain timezone: " + pattern + " [locale: " + locale + "]");
          TimeZone.Rule rule = tz.rule(year);
          switch (n)
          {
            case 1:
              int offset = rule.offset;
              if (dst) offset += rule.dstOffset;
              if (offset == 0) { s.append('Z'); break; }
              if (offset < 0) { s.append('-'); offset = -offset; }
              else { s.append('+'); }
              int zh = offset / 3600;
              int zm = (offset % 3600) / 60;
              if (zh < 10) s.append('0'); s.append(zh).append(':');
              if (zm < 10) s.append('0'); s.append(zm);
              break;
            case 3:
              s.append(dst ? rule.dstAbbr : rule.stdAbbr);
              break;
            case 4:
              s.append(tz.name());
              break;
            default:
              invalidNum = true;
              break;
          }
          break;

        default:
          if (FanInt.isAlpha(c))
            throw ArgErr.make("Invalid pattern: unsupported char '" + (char)c + "'");

          // check for symbol skip
          if (i+1 < len)
          {
            int next = pattern.charAt(i+1);

            // don't display symbol between ss.FFF if fractions is zero
            if (next  == 'F' && ns == 0) break;

            // don't display symbol between mm:SS if secs is zero
            if (next == 'S' && sec == 0 && ns == 0) break;
          }

          s.append((char)c);
      }

      // if invalid number of characters
      if (invalidNum)
        throw ArgErr.make("Invalid pattern: unsupported num of '" + (char)c + "' (x" + n + ")");
    }

    return s.toString();
  }

  private static String daySuffix(int day)
  {
    if (day == 11 || day == 12 || day == 13) return "th";
    switch (day % 10)
    {
      case 1:  return "st";
      case 2:  return "nd";
      case 3:  return "rd";
      default: return "th";
    }
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  DateTime parseDateTime(String s, TimeZone defTz, boolean checked)
  {
    try
    {
      // parse into fields
      tzOffset = Integer.MAX_VALUE;
      parse(s);

      // now figure out what timezone to use
      TimeZone.Rule defRule = defTz.rule(year);
      if (tzName != null)
      {
        // use defTz if tzName was specified and matches any variations of defTz
        if (tzName.equals(defTz.name()) ||
            tzName.equals(defRule.stdAbbr) ||
            tzName.equals(defRule.dstAbbr))
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
      else if (tzOffset != Integer.MAX_VALUE)
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
    catch (Exception e)
    {
      if (checked) throw ParseErr.make("DateTime", s, Err.make(e));
      return null;
    }
  }

  Date parseDate(String s, boolean checked)
  {
    try
    {
      parse(s);
      return new Date(year, (int)mon.ordinal(), day);
    }
    catch (Exception e)
    {
      if (checked) throw ParseErr.make("Date", s, Err.make(e));
      return null;
    }
  }

  Time parseTime(String s, boolean checked)
  {
    try
    {
      parse(s);
      return new Time(hour, min, sec, ns);
    }
    catch (Exception e)
    {
      if (checked) throw ParseErr.make("Time", s, Err.make(e));
      return null;
    }
  }

  private void parse(String s)
  {
    this.str = s;
    this.pos = 0;
    int len = pattern.length();
    boolean skippedLast = false;
    for (int i=0; i<len; ++i)
    {
      // character
      int c = pattern.charAt(i);

      // character count
      int n = 1;
      while (i+1<len && pattern.charAt(i+1) == c) { ++i; ++n; }

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
          int amPm = str.charAt(pos); pos += n;
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

        case 'F':
          if (skippedLast) break;
          // fall-thru

        case 'f':
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
            default: parseTzName();
          }
          break;

        case '\'':
          if (n == 2) // '' means one '
          {
            int actual = str.charAt(pos++);
            if (actual != '\'')
              throw new RuntimeException("Expected single quote, not '" + (char)actual + "' [pos " + pos +"]");
          }
          else
          {
            while (true)
            {
              int expected = pattern.charAt(++i);
              if (expected == '\'') break;
              int actual = str.charAt(pos++);
              if (actual != expected)
                throw new RuntimeException("Expected '" + (char)expected + "', not '" + (char)actual + "' [pos " + pos +"]");
            }
          }
          break;

        default:
          int match = pos+1 < str.length() ? str.charAt(pos++) : 0;

          // handle skipped symbols
          if (i+1 < pattern.length())
          {
            int next = pattern.charAt(i+1);
            if (next == 'F' || next == 'S')
            {
              if (match != c) { skippedLast = true; --pos; break; }
            }
          }

          skippedLast = false;
          if (match != c)
            throw new RuntimeException("Expected '" + (char)c + "' literal char, not '" + (char)match + "' [pos " + pos +"]");
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
    int ch = str.charAt(pos++);
    if ('0' <= ch && ch <= '9') return ch - '0';
    throw new RuntimeException("Expected digit, not '" + (char)ch + "' [pos " + (pos-1) + "]");
  }

  private int parseOptDigit()
  {
    if (pos < str.length())
    {
      int ch = str.charAt(pos);
      if ('0' <= ch && ch <= '9') { pos++; return ch - '0'; }
    }
    return -1;
  }

  private Month parseMon()
  {
    // TODO: this does not handle all the cases yet such as and fr "janv." and zh "10月"
    StringBuilder s = new StringBuilder();
    while (pos < str.length())
    {
      int ch = str.charAt(pos);
      if ('a' <= ch && ch <= 'z') { s.append((char)ch); pos++; continue; }
      if ('A' <= ch && ch <= 'Z') { s.append((char)FanInt.lower(ch)); pos++; continue; }
      if (Character.isAlphabetic(ch)) { s.append((char)Character.toLowerCase(ch)); pos++; continue; }
      break;
    }
    Month m = locale().monthByName(s.toString());
    if (m == null) throw new RuntimeException("Invalid month: " + s);
    return m;
  }

  private void parseTzOffset()
  {
    int ch = str.charAt(pos++);
    boolean neg;
    switch (ch)
    {
      case '-': neg = true; break;
      case '+': neg = false; break;
      case 'Z': tzOffset = 0; return;
      default: throw new RuntimeException("Unexpected tz offset char: " + (char)ch + " [pos " + (pos-1) + "]");
    }

    int hr = parseInt(1);
    int min = 0;
    if (pos < str.length())
    {
      ch = str.charAt(pos);
      if (ch == ':')
      {
        pos++;
        min = parseInt(1);
      }
      else if ('0' <= ch && ch <= '9')
      {
        min = parseInt(1);
      }
    }
    tzOffset = hr*3600 + min*60;
    if (neg) tzOffset = -tzOffset;
  }

  private void parseTzName()
  {
    StringBuilder s = new StringBuilder();
    while (pos < str.length())
    {
      int ch = str.charAt(pos);
      if (('a' <= ch && ch <= 'z') ||
          ('A' <= ch && ch <= 'Z') ||
          ('0' <= ch && ch <= '9') ||
          ch == '+' || ch == '-' || ch == '_')
      {
        s.append((char)ch);
        pos++;
      }
      else break;
    }
    tzName = s.toString();
  }

  private void skipWord()
  {
    while (pos < str.length())
    {
      int ch = str.charAt(pos);
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
    if (locale == null) locale = Locale.cur();
    return locale;
  }

  private int weekOfYear()
  {
    Weekday sow = Weekday.localeStartOfWeek(locale());
    if (val instanceof DateTime) return (int)((DateTime)val).weekOfYear(sow);
    if (val instanceof Date) return (int)((Date)val).weekOfYear(sow);
    return 0;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final String pattern;
  Object val;
  int year;
  Month mon;
  int day;
  int hour;
  int min;
  int sec;
  int ns;
  Weekday weekday;
  TimeZone tz;
  String tzName;
  int tzOffset;
  boolean dst;
  Locale locale;
  String str;  // when parsing
  int pos;     // index in str for parse
}