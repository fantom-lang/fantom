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

  public static final Month jan = new Month(0,  "jan");
  public static final Month feb = new Month(1,  "feb");
  public static final Month mar = new Month(2,  "mar");
  public static final Month apr = new Month(3,  "apr");
  public static final Month may = new Month(4,  "may");
  public static final Month jun = new Month(5,  "jun");
  public static final Month jul = new Month(6,  "jul");
  public static final Month aug = new Month(7,  "aug");
  public static final Month sep = new Month(8,  "sep");
  public static final Month oct = new Month(9,  "oct");
  public static final Month nov = new Month(10, "nov");
  public static final Month dec = new Month(11, "dec");

  static final Month[] array =
  {
    jan, feb, mar, apr, may, jun,
    jul, aug, sep, oct, nov, dec
  };

  public static final List vals = (List)new List(Sys.MonthType, array).toImmutable();

  private Month(int ordinal, String name)
  {
    Enum.make$(this, FanInt.pos[ordinal], name.intern());
    this.ord = ordinal;
    this.localeAbbrKey = name + "Abbr";
    this.localeFullKey = name + "Full";
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

  public String toLocale() { return toLocale(null); }
  public String toLocale(String pattern)
  {
    if (pattern == null) return localeAbbr();
    if (FanStr.isEveryChar(pattern, 'M'))
    {
      switch (pattern.length())
      {
        case 1: return String.valueOf(ord+1);
        case 2: return ord < 9 ? "0" + (ord+1) : String.valueOf(ord+1);
        case 3: return localeAbbr();
        case 4: return localeFull();
      }
    }
    throw ArgErr.make("Invalid pattern: " + pattern).val;
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
  final String localeAbbrKey;
  final String localeFullKey;
}