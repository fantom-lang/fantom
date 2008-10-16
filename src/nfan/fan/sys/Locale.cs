//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 07  Andy Frank  Creation
//

using System;
using System.Globalization;

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

    public static Locale fromStr(string s) { return fromStr(Str.make(s)); }
    public static Locale fromStr(Str str)
    {
      string s = str.val;
      int len = s.Length;
      try
      {
        if (len == 2)
        {
          if (str.isLower().booleanValue())
            return new Locale(str, str, null);
        }

        if (len == 5)
        {
          Str lang = Str.make(s.Substring(0, 2));
          Str country = Str.make(s.Substring(3, 2));
          if (lang.isLower().booleanValue() && country.isUpper().booleanValue() && s[2] == '-')
            return new Locale(str, lang, country);
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
      throw ParseErr.make("Locale",  str).val;
    }

    private Locale(Str str, Str lang, Str country)
    {
      this.m_str     = str;
      this.m_lang    = lang;
      this.m_country = country;
    }

  //////////////////////////////////////////////////////////////////////////
  // Thread
  //////////////////////////////////////////////////////////////////////////

    public static Locale current()
    {
      if (m_current == null) m_current = defaultLocale;
      return m_current;
    }

    public static void setCurrent(Locale locale)
    {
      if (locale == null) throw NullErr.make().val;
      m_current = locale;
    }

    [ThreadStatic] static Locale m_current;

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

    public Str lang() { return m_lang; }

    public Str country() { return m_country; }

    public override Type type() { return Sys.LocaleType; }

    public override int GetHashCode() { return m_str.GetHashCode(); }

    public override Int hash() { return m_str.hash(); }

    public override Boolean _equals(object obj)
    {
      if (obj is Locale)
      {
        return (obj as Locale).m_str._equals(m_str);
      }
      return Boolean.False;
    }

    public override Str toStr() { return m_str; }

    public CultureInfo net()
    {
      if (netCulture == null)
      {
        string n = m_lang.val;
        if (m_country != null) n += "-" + m_country.val;
        netCulture = new CultureInfo(n);
      }
      return netCulture;
    }

  //////////////////////////////////////////////////////////////////////////
  // Properties
  //////////////////////////////////////////////////////////////////////////

    public Str get(Str podName, Str key)
    {
      return doGet(Pod.find(podName, Boolean.False), podName, key, m_getNoDef);
    }

    public Str get(Str podName, Str key, Str def)
    {
      return doGet(Pod.find(podName, Boolean.False), podName, key, def);
    }

    /**
     *   1. Find the pod and use its resource files
     *   2. Lookup via '/locale/{toStr}.props'
     *   3. Lookup via '/locale/{lang}.props'
     *   4. Lookup via '/locale/en.props'
     *   5. If all else fails return 'pod::key'
     */
    internal Str doGet(Pod pod, Str podName, Str key, Str def)
    {
      // 1. Find the pod and use its resource files
      if (pod != null)
      {
        // 2. Lookup via '/locale/{toStr}.props'
        Str val = tryProp(pod, key, m_str);
        if (val != null) return val;

        // 3. Lookup via '/locale/{lang}.props'
        if (m_country != null)
        {
          val = tryProp(pod, key, m_lang);
          if (val != null) return val;
        }

        // 4. Lookup via '/locale/en.props'
        if (m_str.val != "en")
        {
          val = tryProp(pod, key, en);
          if (val != null) return val;
        }
      }

      // 5. If all else fails return def, which defaults to pod::key
      if (def == m_getNoDef) return Str.make(podName + "::" + key);
      return def;
    }

    Str tryProp(Pod pod, Str key, Str locale)
    {
      // get the props for the locale
      Map props;
      lock (pod.locales)
      {
        props = (Map)pod.locales[locale];
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
        System.Console.WriteLine("ERROR: Cannot load " + uri);
        Err.dumpStack(e);
      }

      // now map the loaded props back into the pod's cache
      lock (pod.locales)
      {
        pod.locales[locale] = props;
      }

      // return result
      return (Str)props.get(key);
    }

    static readonly Map noProps = new Map(Sys.StrType, Sys.StrType).ro();
    static readonly Str en = Str.make("en");

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
        x = fromStr(Str.make(name));
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        x = fromStr(Str.make("en"));
      }
      defaultLocale = x;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    // use predefined string to avoid unnecessary string concat
    internal static readonly Str m_getNoDef = Str.make("_locale_nodef_");

    readonly Str m_str;
    readonly Str m_lang;
    readonly Str m_country;
    CultureInfo netCulture;

  }
}