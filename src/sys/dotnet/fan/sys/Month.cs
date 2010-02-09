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

    public static readonly List m_vals = new List(Sys.MonthType, array).ro();

    private Month(int ordinal, string name)
    {
      Enum.make_(this, ordinal, System.String.Intern(name));
      this.ord = ordinal;
      this.localeAbbrKey = name + "Abbr";
      this.localeFullKey = name + "Full";
    }

    public static Month fromStr(string name) { return fromStr(name, true); }
    public static Month fromStr(string name, bool check)
    {
      return (Month)doFromStr(Sys.MonthType, name, check);
    }

    public override Type @typeof() { return Sys.MonthType; }

    public Month increment() { return array[(ord+1)%array.Length]; }

    public Month decrement() { return ord == 0 ? array[array.Length-1] : array[ord-1]; }

    public long numDays(long year)
    {
      if (DateTime.isLeapYear((int)year))
        return DateTime.daysInMonLeap[ord];
      else
        return DateTime.daysInMon[ord];
    }

    public string toLocale() { return toLocale(null); }
    public string toLocale(string pattern)
    {
      if (pattern == null) return localeAbbr();
      if (FanStr.isEveryChar(pattern, 'M'))
      {
        switch (pattern.Length)
        {
          case 1: return ""+(ord+1);
          case 2: return ord < 9 ? "0"+(ord+1) : ""+(ord+1);
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

    internal readonly int ord;
    readonly string localeAbbrKey;
    readonly string localeFullKey;
  }
}