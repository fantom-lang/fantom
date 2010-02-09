//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Feb 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Weekday.
  /// </summary>
  public sealed class Weekday : Enum
  {

    public static readonly Weekday m_sun = new Weekday(0, "sun");
    public static readonly Weekday m_mon = new Weekday(1, "mon");
    public static readonly Weekday m_tue = new Weekday(2, "tue");
    public static readonly Weekday m_wed = new Weekday(3, "wed");
    public static readonly Weekday m_thu = new Weekday(4, "thu");
    public static readonly Weekday m_fri = new Weekday(5, "fri");
    public static readonly Weekday m_sat = new Weekday(6, "sat");

    internal static readonly Weekday[] array =
    {
      m_sun, m_mon, m_tue, m_wed, m_thu, m_fri, m_sat
    };

    public static readonly List m_vals = new List(Sys.WeekdayType, array).ro();

    private Weekday(int ordinal, string name)
    {
      Enum.make_(this, ordinal, System.String.Intern(name));
      this.ord = ordinal;
      this.localeAbbrKey  = name + "Abbr";
      this.localeFullKey  = name + "Full";
    }

    public static Weekday fromStr(string name) { return fromStr(name, true); }
    public static Weekday fromStr(string name, bool check)
    {
      return (Weekday)doFromStr(Sys.WeekdayType, name, check);
    }

    public override Type @typeof() { return Sys.WeekdayType; }

    public Weekday increment() { return array[(ord+1)%array.Length]; }

    public Weekday decrement() { return ord == 0 ? array[array.Length-1] : array[ord-1]; }

    public string toLocale() { return toLocale(null); }
    public string toLocale(string pattern)
    {
      if (pattern == null) return localeAbbr();
      if (FanStr.isEveryChar(pattern, 'W'))
      {
        switch (pattern.Length)
        {
          case 3: return localeAbbr();
          case 4: return localeFull();
        }
      }
      throw ArgErr.make("Invalid pattern: " + pattern).val;
    }

    public string localeAbbr() { return abbr(Locale.cur()); }
    public string abbr(Locale locale)
    {
      return Env.cur().locale(Sys.m_sysPod, localeAbbrKey, name(), locale);
    }

    public string localeFull() { return full(Locale.cur()); }
    public string full(Locale locale)
    {
      return Env.cur().locale(Sys.m_sysPod, localeFullKey, name(), locale);
    }

    public static Weekday localeStartOfWeek()
    {
      return fromStr(Env.cur().locale(Sys.m_sysPod, "weekdayStart", "sun"));
    }

    internal readonly int ord;
    readonly string localeAbbrKey;
    readonly string localeFullKey;
  }
}