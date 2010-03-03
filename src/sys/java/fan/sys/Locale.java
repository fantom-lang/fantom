//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Nov 07  Brian Frank  Creation
//
package fan.sys;

/**
 * Locale
 */
public class Locale
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Locale fromStr(String s) { return fromStr(s, true); }
  public static Locale fromStr(String s, boolean checked)
  {
    int len = s.length();
    try
    {
      if (len == 2)
      {
        if (FanStr.isLower(s))
          return new Locale(s, s, null);
      }

      if (len == 5)
      {
        String lang = s.substring(0, 2);
        String country = s.substring(3, 5);
        if (FanStr.isLower(lang) && FanStr.isUpper(country) && s.charAt(2) == '-')
          return new Locale(s, lang, country);
      }
    }
    catch (Exception e)
    {
    }
    if (!checked) return null;
    throw ParseErr.make("Locale", s).val;
  }

  private Locale(String str, String lang, String country)
  {
    this.str       = str;
    this.lang      = lang;
    this.country   = country;
    this.strProps  = Uri.fromStr("locale/" + str + ".props");
    this.langProps = Uri.fromStr("locale/" + lang + ".props");
  }

//////////////////////////////////////////////////////////////////////////
// Thread
//////////////////////////////////////////////////////////////////////////

  public static Locale cur()
  {
    return (Locale)cur.get();
  }

  public static void setCur(Locale locale)
  {
    if (locale == null) throw NullErr.make().val;
    cur.set(locale);
  }

  static final ThreadLocal cur = new ThreadLocal()
  {
    protected Object initialValue() { return defaultLocale; }
  };

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

  public String lang() { return lang; }

  public String country() { return country; }

  public Type typeof() { return Sys.LocaleType; }

  public int hashCode() { return str.hashCode(); }

  public long hash() { return FanStr.hash(str); }

  public boolean equals(Object obj)
  {
    if (obj instanceof Locale)
    {
      return ((Locale)obj).str.equals(str);
    }
    return false;
  }

  public String toStr() { return str; }

  public java.util.Locale java()
  {
    if (javaLocale == null)
      javaLocale = new java.util.Locale(lang, country == null ? "" : country);
    return javaLocale;
  }

  public java.text.Collator collator()
  {
    if (javaCollator == null)
    {
      javaCollator = java.text.Collator.getInstance(java());
      javaCollator.setStrength(java.text.Collator.PRIMARY);
    }
    return javaCollator;
  }

  public java.text.DecimalFormatSymbols decimal()
  {
    if (javaDecimal == null)
      javaDecimal = new java.text.DecimalFormatSymbols(java());
    return javaDecimal;
  }

  /** Get a month by lowercase abbr or full name for this locale */
  Month monthByName(String name)
  {
    if (monthsByName == null)
    {
      java.util.HashMap map = new java.util.HashMap(31);
      for (int i=0; i<Month.array.length; ++i)
      {
        Month m = Month.array[i];
        map.put(FanStr.lower(m.abbr(this)), m);
        map.put(FanStr.lower(m.full(this)), m);
      }
      monthsByName = map;
    }
    return (Month)monthsByName.get(name);
  }

//////////////////////////////////////////////////////////////////////////
// Default Locale
//////////////////////////////////////////////////////////////////////////

  static final Locale defaultLocale;
  static
  {
    Locale x;
    try
    {
      String lang = java.util.Locale.getDefault().getLanguage();
      String country = java.util.Locale.getDefault().getCountry();
      if (country == null && country.length() == 0)
        x = fromStr(lang);
      else
        x = fromStr(lang + "-" + country);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      x = fromStr("en");
    }
    defaultLocale = x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Locale en = Locale.fromStr("en");

  final String str;
  final String lang;
  final String country;
  public final Uri strProps;    // `locale/{str}.props`
  public final Uri langProps;   // `locale/{lang}.props`
  java.util.Locale javaLocale;
  java.text.Collator javaCollator;
  java.text.DecimalFormatSymbols javaDecimal;
  java.util.HashMap monthsByName;

}