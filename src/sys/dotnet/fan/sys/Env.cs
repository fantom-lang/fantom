//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//

//using System;
//using System.Collections;
//using System.Reflection;
//using System.IO;
using Fanx.Util;

namespace Fan.Sys
{
  public abstract class Env : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Env cur() { return Sys.m_curEnv; }

    public static void make_(Env self) { make_(self, cur()); }
    public static void make_(Env self, Env parent) { self.m_parent = parent; }

    public Env() {}
    public Env(Env parent)
    {
      this.m_parent  = parent;
      this.m_scripts = new EnvScripts();
      this.m_props   = new EnvProps(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.EnvType; }

    public override string toStr() { return @typeof().toStr(); }

  //////////////////////////////////////////////////////////////////////////
  // Non-Virtuals
  //////////////////////////////////////////////////////////////////////////

    public Env parent() { return m_parent; }

    public string os() { return Sys.m_os; }

    public string arch() { return Sys.m_arch; }

    public string platform() { return Sys.m_platform; }

    public string runtime() { return "dotnet"; }

    public long idHash(object obj) { return System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(obj); }

  //////////////////////////////////////////////////////////////////////////
  // Virtuals
  //////////////////////////////////////////////////////////////////////////

    public List args() { return m_parent.args(); }

    public Map vars()  { return m_parent.vars(); }

    public Map diagnostics() { return m_parent.diagnostics(); }

    public void gc() { m_parent.gc(); }

    public string host() { return m_parent.host(); }

    public string user() { return m_parent.user(); }

    public void exit() { this.exit(0); }
    public void exit(long status) { m_parent.exit(status); }

    public InStream @in() { return m_parent.@in(); }

    public OutStream @out() { return m_parent.@out(); }

    public OutStream err() { return m_parent.err(); }

    public File homeDir() { return m_parent.homeDir(); }

    public File workDir() { return m_parent.workDir(); }

    public File tempDir() { return m_parent.tempDir(); }

  //////////////////////////////////////////////////////////////////////////
  // Resolution
  //////////////////////////////////////////////////////////////////////////

    public File findFile(string uri) { return findFile(Uri.fromStr(uri), true); }
    public File findFile(string uri, bool check) { return findFile(Uri.fromStr(uri), check); }
    public File findFile(Uri uri) { return findFile(uri, true); }
    public File findFile(Uri uri, bool check)
    {
      return m_parent.findFile(uri, check);
    }

    public List findAllFiles(string uri) { return findAllFiles(Uri.fromStr(uri)); }
    public List findAllFiles(Uri uri)
    {
      return m_parent.findAllFiles(uri);
    }

    public File findPodFile(string name)
    {
      return findFile(Uri.fromStr("lib/fan/" + name + ".pod"), false);
    }

    public List findAllPodNames()
    {
      List acc = new List(Sys.StrType);
      List files = findFile(Uri.fromStr("lib/fan/")).list();
      for (int i=0; i<files.sz(); ++i)
      {
        File f = (File)files.get(i);
        if (f.isDir() || "pod" != f.ext()) continue;
        acc.add(f.basename());
      }
      return acc;
    }

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    public Type compileScript(File file) { return compileScript(file, null); }
    public Type compileScript(File file, Map options)
    {
      return m_scripts.compile(file, options);
    }

    public List index(string key)
    {
// TODO-FACETS
//      return m_index.get(key);
return null;
    }

    public Map props(Pod pod, Uri uri, Duration maxAge)
    {
      return m_props.get(pod, uri, maxAge);
    }

    public string config(Pod pod, string key) { return config(pod, key, null); }
    public string config(Pod pod, string key, string def)
    {
      return (string)m_props.get(pod, m_configProps, Duration.m_oneMin).get(key, def);
    }

    public string locale(Pod pod, string key) { return locale(pod, key, m_noDef, Locale.cur()); }
    public string locale(Pod pod, string key, string def) { return locale(pod, key, def, Locale.cur()); }
    public string locale(Pod pod, string key, string def, Locale locale)
    {
      object val;
      Duration maxAge = Duration.m_maxVal;

      // 1. 'props(pod, `locale/{locale}.props`)'
      val = props(pod, locale.m_strProps, maxAge).get(key, null);
      if (val != null) return (string)val;

      // 2. 'props(pod, `locale/{lang}.props`)'
      val = props(pod, locale.m_langProps, maxAge).get(key, null);
      if (val != null) return (string)val;

      // 3. 'props(pod, `locale/en.props`)'
      val = props(pod, m_localeEnProps, maxAge).get(key, null);
      if (val != null) return (string)val;

      // 4. Fallback to 'pod::key' unless 'def' specified
      if (def == m_noDef) return pod + "::" + key;
      return def;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static readonly string m_noDef = "_Env_nodef_";
    static Uri m_configProps    = Uri.fromStr("config.props");
    static Uri m_localeEnProps  = Uri.fromStr("locale/en.props");

    private Env m_parent;
    private EnvScripts m_scripts;
    private EnvProps m_props;
//    private EnvIndex m_index = new EnvIndex(this);
  }
}