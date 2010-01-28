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

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public Type compileScript(fan.sys.File file) { return compileScript(file, null); }
  public Type compileScript(fan.sys.File file, Map options)
  {
    return scripts.compile(file, options);
  }

  public Map props(Uri uri) { return props(uri, Duration.oneMin); }
  public Map props(Uri uri, Duration maxAge)
  {
    return props.get(uri, maxAge);
  }

  public String config(String podName, String keyName) { return config(podName, keyName, null); }
  public String config(String podName, String keyName, String def)
  {
    String uri = "etc/" + podName + "/config.props";
    return (String)props.get(uri, Duration.oneMin).get(keyName, def);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Env parent;
  private ScriptCache scripts = new ScriptCache();
  private PropsCache props = new PropsCache(this);
}