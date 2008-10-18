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

  public static final Weekday sun = new Weekday(0, "sun");
  public static final Weekday mon = new Weekday(1, "mon");
  public static final Weekday tue = new Weekday(2, "tue");
  public static final Weekday wed = new Weekday(3, "wed");
  public static final Weekday thu = new Weekday(4, "thu");
  public static final Weekday fri = new Weekday(5, "fri");
  public static final Weekday sat = new Weekday(6, "sat");

  static final Weekday[] array = { sun, mon, tue, wed, thu, fri, sat };

  public static final List values = new List(Sys.WeekdayType, array).ro();

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

  public Type type() { return Sys.WeekdayType; }

  public Weekday increment() { return array[(ord+1)%array.length]; }

  public Weekday decrement() { return ord == 0 ? array[array.length-1] : array[ord-1]; }

  public String toLocale() { return toLocale(null); }
  public String toLocale(String pattern)
  {
    if (pattern == null) return localeAbbr();
    if (FanStr.isEveryChar(pattern, 'W'))
    {
      switch (pattern.length())
      {
        case 3: return localeAbbr();
        case 4: return localeFull();
      }
    }
    throw ArgErr.make("Invalid pattern: " + pattern).val;
  }

  public String localeAbbr() { return abbr(Locale.current()); }
  public String abbr(Locale locale)
  {
    return locale.get("sys", localeAbbrKey);
  }

  public String localeFull() { return full(Locale.current()); }
  public String full(Locale locale)
  {
    return locale.get("sys", localeFullKey);
  }

  public static Weekday localeStartOfWeek()
  {
    return fromStr(Locale.current().get("sys", "weekdayStart"));
  }

  final int ord;
  final String localeAbbrKey;
  final String localeFullKey;
}
