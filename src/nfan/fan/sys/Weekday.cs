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

    public static readonly List m_values = new List(Sys.WeekdayType, array).ro();

    private Weekday(int ordinal, string name)
    {
      Enum.make_(this, Int.m_pos[ordinal], Str.make(name).intern());
      this.ord = ordinal;
      this.localeAbbrKey  = Str.make(name + "Abbr");
      this.localeFullKey  = Str.make(name + "Full");
    }

    public static Weekday fromStr(Str name) { return fromStr(name, Bool.True); }
    public static Weekday fromStr(Str name, Bool check)
    {
      return (Weekday)doFromStr(Sys.WeekdayType, name, check);
    }

    public override Type type() { return Sys.WeekdayType; }

    public Weekday increment() { return array[(ord+1)%array.Length]; }

    public Weekday decrement() { return ord == 0 ? array[array.Length-1] : array[ord-1]; }

    public Str toLocale() { return toLocale(null); }
    public Str toLocale(Str pattern)
    {
      if (pattern == null) return localeAbbr();
      if (pattern.isEveryChar('W'))
      {
        switch (pattern.val.Length)
        {
          case 3: return localeAbbr();
          case 4: return localeFull();
        }
      }
      throw ArgErr.make("Invalid pattern: " + pattern).val;
    }

    public Str localeAbbr() { return abbr(Locale.current()); }
    public Str abbr(Locale locale)
    {
      return locale.get(Str.sysStr, localeAbbrKey);
    }

    public Str localeFull() { return full(Locale.current()); }
    public Str full(Locale locale)
    {
      return locale.get(Str.sysStr, localeFullKey);
    }

    public static Weekday localeStartOfWeek()
    {
      return fromStr(Locale.current().get(Str.sysStr, localeStartKey));
    }

    static readonly Str localeStartKey = Str.make("weekdayStart");

    internal readonly int ord;
    readonly Str localeAbbrKey;
    readonly Str localeFullKey;
  }
}
