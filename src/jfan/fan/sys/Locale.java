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

  public static Locale fromStr(String s) { return fromStr(Str.make(s)); }
  public static Locale fromStr(Str str)
  {
    String s = str.val;
    int len = s.length();
    try
    {
      if (len == 2)
      {
        if (str.isLower().val)
          return new Locale(str, str, null);
      }

      if (len == 5)
      {
        Str lang = Str.make(s.substring(0, 2));
        Str country = Str.make(s.substring(3, 5));
        if (lang.isLower().val && country.isUpper().val && s.charAt(2) == '-')
          return new Locale(str, lang, country);
      }
    }
    catch (Exception e)
    {
    }
    throw ParseErr.make("Locale",  str).val;
  }

  private Locale(Str str, Str lang, Str country)
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

  public Str lang() { return lang; }

  public Str country() { return country; }

  public Type type() { return Sys.LocaleType; }

  public int hashCode() { return str.hashCode(); }

  public Int hash() { return str.hash(); }

  public Bool _equals(Obj obj)
  {
    if (obj instanceof Locale)
    {
      return ((Locale)obj).str._equals(str);
    }
    return Bool.False;
  }

  public Str toStr() { return str; }

  public java.util.Locale java()
  {
    if (javaLocale == null)
      javaLocale = new java.util.Locale(lang.val, country == null ? "" : country.val);
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

  public Str get(Str podName, Str key)
  {
    return doGet(Pod.find(podName, Bool.False), podName, key, getNoDef);
  }

  public Str get(Str podName, Str key, Str def)
  {
    return doGet(Pod.find(podName, Bool.False), podName, key, def);
  }

  /**
   *   1. Find the pod and use its resource files
   *   2. Lookup via '/locale/{toStr}.props'
   *   3. Lookup via '/locale/{lang}.props'
   *   4. Lookup via '/locale/en.props'
   *   5. If all else fails return 'pod::key'
   */
  Str doGet(Pod pod, Str podName, Str key, Str def)
  {
    // 1. Find the pod and use its resource files
    if (pod != null)
    {
      // 2. Lookup via '/locale/{toStr}.props'
      Str val = tryProp(pod, key, str);
      if (val != null) return val;

      // 3. Lookup via '/locale/{lang}.props'
      if (country != null)
      {
        val = tryProp(pod, key, lang);
        if (val != null) return val;
      }

      // 4. Lookup via '/locale/en.props'
      if (!str.val.equals("en"))
      {
        val = tryProp(pod, key, en);
        if (val != null) return val;
      }
    }

    // 5. If all else fails return def, which defaults to pod::key
    if (def == getNoDef) return Str.make(podName + "::" + key);
    return def;
  }

  Str tryProp(Pod pod, Str key, Str locale)
  {
    // get the props for the locale
    Map props;
    synchronized(pod.locales)
    {
      props = (Map)pod.locales.get(locale);
    }

    // if already loaded, lookup key
    if (props != null) return (Str)props.get(key);

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
    return (Str)props.get(key);
  }

  static final Map noProps = new Map(Sys.StrType, Sys.StrType).ro();
  static final Str en = Str.make("en");

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
      x = fromStr(Str.make("en"));
    }
    defaultLocale = x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // use predefined string to avoid unnecessary string concat
  static final Str getNoDef = Str.make("_locale_nodef_");

  final Str str;
  final Str lang;
  final Str country;
  java.util.Locale javaLocale;
  java.text.Collator javaCollator;

}