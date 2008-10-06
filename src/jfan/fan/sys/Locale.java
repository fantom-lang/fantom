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

  public static Locale fromStr(String s)
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
    throw ParseErr.make("Locale", s).val;
  }

  private Locale(String str, String lang, String country)
  {
    this.str     = str;
    this.lang    = lang;
    this.country = country;
  }

//////////////////////////////////////////////////////////////////////////
// Thread
//////////////////////////////////////////////////////////////////////////

  public static Locale current()
  {
    return (Locale)current.get();
  }

  public static void setCurrent(Locale locale)
  {
    if (locale == null) throw NullErr.make().val;
    current.set(locale);
  }

  static final ThreadLocal current = new ThreadLocal()
  {
    protected Object initialValue() { return defaultLocale; }
  };

  public void with(Func func)
  {
    Locale old = current();
    try
    {
      setCurrent(this);
      func.call0();
    }
    finally
    {
      setCurrent(old);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String lang() { return lang; }

  public String country() { return country; }

  public Type type() { return Sys.LocaleType; }

  public int hashCode() { return str.hashCode(); }

  public Long hash() { return FanStr.hash(str); }

  public Boolean _equals(Object obj)
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

//////////////////////////////////////////////////////////////////////////
// Properties
//////////////////////////////////////////////////////////////////////////

  public String get(String podName, String key)
  {
    return doGet(Pod.find(podName, false), podName, key, getNoDef);
  }

  public String get(String podName, String key, String def)
  {
    return doGet(Pod.find(podName, false), podName, key, def);
  }

  /**
   *   1. Find the pod and use its resource files
   *   2. Lookup via '/locale/{toStr}.props'
   *   3. Lookup via '/locale/{lang}.props'
   *   4. Lookup via '/locale/en.props'
   *   5. If all else fails return 'pod::key'
   */
  String doGet(Pod pod, String podName, String key, String def)
  {
    // 1. Find the pod and use its resource files
    if (pod != null)
    {
      // 2. Lookup via '/locale/{toStr}.props'
      String val = tryProp(pod, key, str);
      if (val != null) return val;

      // 3. Lookup via '/locale/{lang}.props'
      if (country != null)
      {
        val = tryProp(pod, key, lang);
        if (val != null) return val;
      }

      // 4. Lookup via '/locale/en.props'
      if (!str.equals("en"))
      {
        val = tryProp(pod, key, "en");
        if (val != null) return val;
      }
    }

    // 5. If all else fails return def, which defaults to pod::key
    if (def == getNoDef) return podName + "::" + key;
    return def;
  }

  String tryProp(Pod pod, String key, String locale)
  {
    // get the props for the locale
    Map props;
    synchronized(pod.locales)
    {
      props = (Map)pod.locales.get(locale);
    }

    // if already loaded, lookup key
    if (props != null) return (String)props.get(key);

    // the props for this locale is not
    // loaded yet, so let's load it!
    Uri uri = Uri.fromStr("/locale/" + locale + ".props");
    try
    {
      // resolve to file
      File f = (File)pod.files().get(uri);

      // if file found, then read into props
      if (f != null)
        props = f.readProps();
      else
        props = noProps;

    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot load " + uri);
      System.out.println("  " + e);
    }

    // now map the loaded props back into the pod's cache
    synchronized(pod.locales)
    {
      pod.locales.put(locale, props);
    }

    // return result
    return (String)props.get(key);
  }

  static final Map noProps = new Map(Sys.StrType, Sys.StrType).ro();

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

  // use predefined string to avoid unnecessary string concat
  static final String getNoDef = "_locale_nodef_";

  final String str;
  final String lang;
  final String country;
  java.util.Locale javaLocale;
  java.text.Collator javaCollator;

}
