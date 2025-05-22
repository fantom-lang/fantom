//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Brian Frank  Creation
//
package fan.sys;

/**
 * Month
 */
public final class Month
  extends Enum
{
  public static final int JAN = 0;
  public static final int FEB = 1;
  public static final int MAR = 2;
  public static final int APR = 3;
  public static final int MAY = 4;
  public static final int JUN = 5;
  public static final int JUL = 6;
  public static final int AUG = 7;
  public static final int SEP = 8;
  public static final int OCT = 9;
  public static final int NOV = 10;
  public static final int DEC = 11;

  public static final Month jan = new Month(JAN, "jan", 1);
  public static final Month feb = new Month(FEB, "feb", 1);
  public static final Month mar = new Month(MAR, "mar", 1);
  public static final Month apr = new Month(APR, "apr", 2);
  public static final Month may = new Month(MAY, "may", 2);
  public static final Month jun = new Month(JUN, "jun", 2);
  public static final Month jul = new Month(JUL, "jul", 3);
  public static final Month aug = new Month(AUG, "aug", 3);
  public static final Month sep = new Month(SEP, "sep", 3);
  public static final Month oct = new Month(OCT, "oct", 4);
  public static final Month nov = new Month(NOV, "nov", 4);
  public static final Month dec = new Month(DEC, "dec", 4);

  static final Month[] array =
  {
    jan, feb, mar, apr, may, jun,
    jul, aug, sep, oct, nov, dec
  };

  public static final List<Month> vals = (List)new List(Sys.MonthType, array).toImmutable();

  public static Month fromOrdinal(int ord) { return array[ord]; }

  private Month(int ordinal, String name, int quarter)
  {
    Enum.make$(this, FanInt.pos[ordinal], name.intern());
    this.ord = ordinal;
    this.localeAbbrKey = name + "Abbr";
    this.localeFullKey = name + "Full";
    this.quarter = quarter;
  }

  public static Month fromStr(String name) { return fromStr(name, true); }
  public static Month fromStr(String name, boolean checked)
  {
    return (Month)doFromStr(Sys.MonthType, name, checked);
  }

  public Type typeof() { return Sys.MonthType; }

  public Month increment() { return array[(ord+1)%array.length]; }

  public Month decrement() { return ord == 0 ? array[array.length-1] : array[ord-1]; }

  public long numDays(long year)
  {
    if (DateTime.isLeapYear((int)year))
      return DateTime.daysInMonLeap[ord];
    else
      return DateTime.daysInMon[ord];
  }

  public String toLocale() { return toLocale(null, null); }
  public String toLocale(String pattern) { return toLocale(pattern, null); }
  public String toLocale(String pattern, Locale locale)
  {
    if (locale == null) locale = Locale.cur();
    if (pattern == null) return abbr(locale);
    if (FanStr.isEveryChar(pattern, 'M'))
    {
      switch (pattern.length())
      {
        case 1: return String.valueOf(ord+1);
        case 2: return ord < 9 ? "0" + (ord+1) : String.valueOf(ord+1);
        case 3: return abbr(locale);
        case 4: return full(locale);
      }
    }
    throw ArgErr.make("Invalid pattern: " + pattern);
  }

  public String localeAbbr() { return abbr(Locale.cur()); }
  public String abbr(Locale locale)
  {
    return Env.cur().locale(Sys.sysPod, localeAbbrKey, name(), locale);
  }

  public String localeFull() { return full(Locale.cur()); }
  public String full(Locale locale)
  {
    return Env.cur().locale(Sys.sysPod, localeFullKey, name(), locale);
  }

  final int ord;
  final int quarter;
  final String localeAbbrKey;
  final String localeFullKey;
}

