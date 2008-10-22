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

    public static Locale fromStr(string s)
    {
      int len = s.Length;
      try
      {
        if (len == 2)
        {
          if (FanStr.isLower(s).booleanValue())
            return new Locale(s, s, null);
        }

        if (len == 5)
        {
          string lang = s.Substring(0, 2);
          string country = s.Substring(3, 2);
          if (FanStr.isLower(lang).booleanValue() && FanStr.isUpper(country).booleanValue() && s[2] == '-')
            return new Locale(s, lang, country);
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
      throw ParseErr.make("Locale",  s).val;
    }

    private Locale(string str, string lang, string country)
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

    public string lang() { return m_lang; }

    public string country() { return m_country; }

    public override Type type() { return Sys.LocaleType; }

    public override int GetHashCode() { return m_str.GetHashCode(); }

    public override Long hash() { return FanStr.hash(m_str); }

    public override Boolean _equals(object obj)
    {
      if (obj is Locale)
      {
        return (obj as Locale).m_str == m_str ? Boolean.True : Boolean.False;
      }
      return Boolean.False;
    }

    public override string toStr() { return m_str; }

    public CultureInfo net()
    {
      if (netCulture == null)
      {
        string n = m_lang;
        if (m_country != null) n += "-" + m_country;
        netCulture = new CultureInfo(n);
      }
      return netCulture;
    }

  //////////////////////////////////////////////////////////////////////////
  // Properties
  //////////////////////////////////////////////////////////////////////////

    public string get(string podName, string key)
    {
      return doGet(Pod.find(podName, Boolean.False), podName, key, m_getNoDef);
    }

    public string get(string podName, string key, string def)
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
    internal string doGet(Pod pod, string podName, string key, string def)
    {
      // 1. Find the pod and use its resource files
      if (pod != null)
      {
        // 2. Lookup via '/locale/{toStr}.props'
        string val = tryProp(pod, key, m_str);
        if (val != null) return val;

        // 3. Lookup via '/locale/{lang}.props'
        if (m_country != null)
        {
          val = tryProp(pod, key, m_lang);
          if (val != null) return val;
        }

        // 4. Lookup via '/locale/en.props'
        if (m_str != "en")
        {
          val = tryProp(pod, key, en);
          if (val != null) return val;
        }
      }

      // 5. If all else fails return def, which defaults to pod::key
      if (def == m_getNoDef) return podName + "::" + key;
      return def;
    }

    string tryProp(Pod pod, string key, string locale)
    {
      // get the props for the locale
      Map props;
      lock (pod.locales)
      {
        props = (Map)pod.locales[locale];
      }

      // if already loaded, lookup key
      if (props != null) return (string)props.get(key);

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
      return (string)props.get(key);
    }

    static readonly Map noProps = new Map(Sys.StrType, Sys.StrType).ro();
    static readonly string en = "en";

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
    CultureInfo netCulture;

  }
}