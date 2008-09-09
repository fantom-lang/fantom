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
  /// Month.
  /// </summary>
  public sealed class Month : Enum
  {

    public static readonly Month m_jan = new Month(0,  "jan");
    public static readonly Month m_feb = new Month(1,  "feb");
    public static readonly Month m_mar = new Month(2,  "mar");
    public static readonly Month m_apr = new Month(3,  "apr");
    public static readonly Month m_may = new Month(4,  "may");
    public static readonly Month m_jun = new Month(5,  "jun");
    public static readonly Month m_jul = new Month(6,  "jul");
    public static readonly Month m_aug = new Month(7,  "aug");
    public static readonly Month m_sep = new Month(8,  "sep");
    public static readonly Month m_oct = new Month(9,  "oct");
    public static readonly Month m_nov = new Month(10, "nov");
    public static readonly Month m_dec = new Month(11, "dec");

    internal static readonly Month[] array =
    {
      m_jan, m_feb, m_mar, m_apr, m_may, m_jun,
      m_jul, m_aug, m_sep, m_oct, m_nov, m_dec
    };

    public static readonly List m_values = new List(Sys.MonthType, array).ro();

    private Month(int ordinal, string name)
    {
      Enum.make_(this, Int.m_pos[ordinal], Str.make(name).intern());
      this.ord = ordinal;
      this.localeAbbrKey = Str.make(name + "Abbr");
      this.localeFullKey = Str.make(name + "Full");
    }

    public static Month fromStr(Str name) { return fromStr(name, Bool.True); }
    public static Month fromStr(Str name, Bool check)
    {
      return (Month)doFromStr(Sys.MonthType, name, check);
    }

    public override Type type() { return Sys.MonthType; }

    public Month increment() { return array[(ord+1)%array.Length]; }

    public Month decrement() { return ord == 0 ? array[array.Length-1] : array[ord-1]; }

    public Int numDays(Int year)
    {
      if (DateTime.isLeapYear((int)year.val))
        return Int.m_pos[DateTime.daysInMonLeap[ord]];
      else
        return Int.m_pos[DateTime.daysInMon[ord]];
    }

    public Str toLocale() { return toLocale(null); }
    public Str toLocale(Str pattern)
    {
      if (pattern == null) return localeAbbr();
      if (pattern.isEveryChar('M'))
      {
        switch (pattern.val.Length)
        {
          case 1: return Str.make(""+(ord+1));
          case 2: return Str.make(ord < 9 ? "0" + (ord+1) : ""+(ord+1));
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

    internal readonly int ord;
    readonly Str localeAbbrKey;
    readonly Str localeFullKey;
  }
}