//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 07  Andy Frank  Creation
//

using System;
using System.Globalization;
using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// Locale.
  /// </summary>
  public class Locale : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Locale fromStr(string s) { return fromStr(s, true); }
    public static Locale fromStr(string s, bool check)
    {
      int len = s.Length;
      try
      {
        if (len == 2)
        {
          if (FanStr.isLower(s))
            return new Locale(s, s, null);
        }

        if (len == 5)
        {
          string lang = s.Substring(0, 2);
          string country = s.Substring(3, 2);
          if (FanStr.isLower(lang) && FanStr.isUpper(country) && s[2] == '-')
            return new Locale(s, lang, country);
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
      if (!check) return null;
      throw ParseErr.make("Locale",  s).val;
    }

    private Locale(string str, string lang, string country)
    {
      this.m_str       = str;
      this.m_lang      = lang;
      this.m_country   = country;
      this.m_strProps  = Uri.fromStr("locale/" + str + ".props");
      this.m_langProps = Uri.fromStr("locale/" + lang + ".props");
    }

  //////////////////////////////////////////////////////////////////////////
  // Thread
  //////////////////////////////////////////////////////////////////////////

    public static Locale cur()
    {
      if (m_cur == null) m_cur = defaultLocale;
      return m_cur;
    }

    public static void setCur(Locale locale)
    {
      if (locale == null) throw NullErr.make().val;
      m_cur = locale;
    }

    [ThreadStatic] static Locale m_cur;

    public Locale use(Func func)
    {
      Locale old = cur();
      try
      {
        setCur(this);
        func.call(this);
      }
      finally
      {
        setCur(old);
      }
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string lang() { return m_lang; }

    public string country() { return m_country; }

    public override Type @typeof() { return Sys.LocaleType; }

    public override int GetHashCode() { return m_str.GetHashCode(); }

    public override long hash() { return FanStr.hash(m_str); }

    public override bool Equals(object obj)
    {
      if (obj is Locale)
      {
        return (obj as Locale).m_str == m_str;
      }
      return false;
    }

    public override string toStr() { return m_str; }

    public CultureInfo dotnet()
    {
      if (dotnetCulture == null)
      {
        string n = m_lang;
        if (m_country != null) n += "-" + m_country;
        dotnetCulture = new CultureInfo(n);
      }
      return dotnetCulture;
    }

    public NumberFormatInfo dec()
    {
      if (m_dec == null)
        m_dec = dotnet().NumberFormat;
      return m_dec;
    }

    /** Get a month by lowercase abbr or full name for this locale */
    internal Month monthByName(string name)
    {
      if (m_monthsByName == null)
      {
        Hashtable map = new Hashtable();
        for (int i=0; i<Month.array.Length; ++i)
        {
          Month m = Month.array[i];
          map[FanStr.lower(m.abbr(this))] = m;
          map[FanStr.lower(m.full(this))] = m;
        }
        m_monthsByName = map;
      }
      return (Month)m_monthsByName[name];
    }

  //////////////////////////////////////////////////////////////////////////
  // Default Locale
  //////////////////////////////////////////////////////////////////////////

    static readonly Locale defaultLocale;
    static Locale()
    {
      Locale x;
      try
      {
        string name = CultureInfo.CurrentCulture.Name;
        if (name.Length != 5)
          name = CultureInfo.CurrentCulture.TwoLetterISOLanguageName;
        x = fromStr(name);
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        x = fromStr("en");
      }
      defaultLocale = x;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    // use predefined string to avoid unnecessary string concat
    internal static readonly string m_getNoDef = "_locale_nodef_";

    readonly string m_str;
    readonly string m_lang;
    readonly string m_country;
    public readonly Uri m_strProps;    // `locale/{str}.props`
    public readonly Uri m_langProps;   // `locale/{lang}.props`
    CultureInfo dotnetCulture;
    NumberFormatInfo m_dec;
    Hashtable m_monthsByName;

  }
}