//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;
import fanx.util.*;

/**
 * Env
 */
public abstract class Env
  extends FanObj
{

  static { Sys.boot(); }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Env cur() { return Sys.curEnv; }

  public static void make$(Env self) { make$(self, cur()); }
  public static void make$(Env self, Env parent) { self.parent = parent; }

  public Env() {}
  public Env(Env parent) { this.parent = parent; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.EnvType; }

  public String toStr() { return typeof().toString(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  public final Env parent() { return parent; }

  public final String os() { return Sys.os; }

  public final String arch() { return Sys.arch; }

  public final String platform() { return Sys.platform; }

  public final String runtime() { return "java"; }

  public final long idHash(Object obj) { return System.identityHashCode(obj); }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  public List args() { return parent.args(); }

  public Map vars()  { return parent.vars(); }

  public Map diagnostics() { return parent.diagnostics(); }

  public void gc() { parent.gc(); }

  public String host() { return parent.host(); }

  public String user() { return parent.user(); }

  public void exit() { this.exit(0); }
  public void exit(long status) { parent.exit(status); }

  public InStream in() { return parent.in(); }

  public OutStream out() { return parent.out(); }

  public OutStream err() { return parent.err(); }

  public File homeDir() { return parent.homeDir(); }

  public File workDir() { return parent.workDir(); }

  public File tempDir() { return parent.tempDir(); }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  public final File findFile(String uri) { return findFile(Uri.fromStr(uri), true); }
  public final File findFile(String uri, boolean checked) { return findFile(Uri.fromStr(uri), checked); }
  public File findFile(Uri uri) { return findFile(uri, true); }
  public File findFile(Uri uri, boolean checked)
  {
    return parent.findFile(uri, checked);
  }

  public final List findAllFiles(String uri) { return findAllFiles(Uri.fromStr(uri)); }
  public List findAllFiles(Uri uri)
  {
    return parent.findAllFiles(uri);
  }

  public File findPodFile(String name)
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
      if (f.isDir() || !"pod".equals(f.ext())) continue;
      acc.add(f.basename());
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public Type compileScript(fan.sys.File file) { return compileScript(file, null); }
  public Type compileScript(fan.sys.File file, Map options)
  {
    return scripts.compile(file, options);
  }

  public List index(String key)
  {
    return index.get(key);
  }

  public Map props(Pod pod, Uri uri, Duration maxAge)
  {
    return props.get(pod, uri, maxAge);
  }

  public String config(Pod pod, String key) { return config(pod, key, null); }
  public String config(Pod pod, String key, String def)
  {
    return (String)props.get(pod, configProps, Duration.oneMin).get(key, def);
  }

  public String locale(Pod pod, String key) { return locale(pod, key, noDef, Locale.cur()); }
  public String locale(Pod pod, String key, String def) { return locale(pod, key, def, Locale.cur()); }
  public String locale(Pod pod, String key, String def, Locale locale)
  {
    Object val;
    Duration maxAge = Duration.maxVal;

    // 1. 'props(pod, `locale/{locale}.props`)'
    val = props(pod, locale.strProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 2. 'props(pod, `locale/{lang}.props`)'
    val = props(pod, locale.langProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 3. 'props(pod, `locale/en.props`)'
    val = props(pod, localeEnProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 4. Fallback to 'pod::key' unless 'def' specified
    if (def == noDef) return pod + "::" + key;
    return def;
  }

//////////////////////////////////////////////////////////////////////////
// Java Env
//////////////////////////////////////////////////////////////////////////

  /**
   * Load the Java class representation of Pod constants.
   * Default implementation delegates to parent.
   */
  public Class loadPodClass(Pod pod)
  {
    return parent.loadPodClass(pod);
  }

  /**
   * Load the Java class representations of a Fantom type:
   *   - Fantom class => [class]
   *   - Fantom mixin => [interface, body class]
   *   - Fantom Err class => [class, val class]
   * Default implementation delegates to parent.
   */
  public Class[] loadTypeClasses(ClassType t)
  {
    return parent.loadTypeClasses(t);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final String noDef = "_Env_nodef_";
  static Uri configProps    = Uri.fromStr("config.props");
  static Uri localeEnProps  = Uri.fromStr("locale/en.props");

  private Env parent;
  private EnvScripts scripts = new EnvScripts();
  private EnvProps props = new EnvProps(this);
  private EnvIndex index = new EnvIndex(this);
}