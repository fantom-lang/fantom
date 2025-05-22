//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Brian Frank  Creation
//
package fan.sys;

/**
 * Weekday
 */
public final class Weekday
  extends Enum
{
  public static final int SUN = 0;
  public static final int MON = 1;
  public static final int TUE = 2;
  public static final int WED = 3;
  public static final int THU = 4;
  public static final int FRI = 5;
  public static final int SAT = 6;

  public static final Weekday sun = new Weekday(SUN, "sun");
  public static final Weekday mon = new Weekday(MON, "mon");
  public static final Weekday tue = new Weekday(TUE, "tue");
  public static final Weekday wed = new Weekday(WED, "wed");
  public static final Weekday thu = new Weekday(THU, "thu");
  public static final Weekday fri = new Weekday(FRI, "fri");
  public static final Weekday sat = new Weekday(SAT, "sat");

  static final Weekday[] array = { sun, mon, tue, wed, thu, fri, sat };

  public static final List<Weekday> vals = (List)new List(Sys.WeekdayType, array).toImmutable();

  private Weekday(int ordinal, String name)
  {
    Enum.make$(this, FanInt.pos[ordinal], name.intern());
    this.ord = ordinal;
    this.localeAbbrKey  = name + "Abbr";
    this.localeFullKey  = name + "Full";
  }

  public static Weekday fromStr(String name) { return fromStr(name, true); }
  public static Weekday fromStr(String name, boolean checked)
  {
    return (Weekday)doFromStr(Sys.WeekdayType, name, checked);
  }

  public Type typeof() { return Sys.WeekdayType; }

  public Weekday increment() { return array[(ord+1)%array.length]; }

  public Weekday decrement() { return ord == 0 ? array[array.length-1] : array[ord-1]; }

  public String toLocale() { return toLocale(null, null); }
  public String toLocale(String pattern) { return toLocale(pattern, null); }
  public String toLocale(String pattern, Locale locale)
  {
    if (locale == null) locale = Locale.cur();
    if (pattern == null) return abbr(locale);
    if (FanStr.isEveryChar(pattern, 'W'))
    {
      switch (pattern.length())
      {
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

  public static Weekday localeStartOfWeek() { return localeStartOfWeek(Locale.cur()); }
  static Weekday localeStartOfWeek(Locale locale)
  {
    return fromStr(Env.cur().locale(Sys.sysPod, "weekdayStart", "sun", locale));
  }

  public static List<Weekday> localeVals()
  {
    Weekday start = localeStartOfWeek();
    List list = localeVals[start.ord];
    if (list == null)
    {
      list = new List(Sys.WeekdayType, 7);
      for (int i=0; i<7; ++i)
        list.add(array[(i + start.ord) % 7]);
      localeVals[start.ord] = (List)list.toImmutable();
    }
    return list;
  }
  private static final List[] localeVals = new List[7];

  final int ord;
  final String localeAbbrKey;
  final String localeFullKey;
}

