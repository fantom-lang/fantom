//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;

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

  public Type compileScript(fan.sys.File file) { return this.compileScript(file, null); }
  public Type compileScript(fan.sys.File file, Map options) { return parent.compileScript(file, options); }

  public final File findFile(String uri) { return findFile(Uri.fromStr(uri), true); }
  public final File findFile(String uri, boolean checked) { return findFile(Uri.fromStr(uri), checked); }
  public File findFile(Uri uri) { return this.findFile(uri, true); }
  public File findFile(Uri uri, boolean checked) { return parent.findFile(uri, checked); }

  public final List findAllFiles(String uri) { return findAllFiles(Uri.fromStr(uri)); }
  public List findAllFiles(Uri uri) { return parent.findAllFiles(uri); }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  public final Map props(Uri uri) { return props(uri, Duration.oneMin); }
  public final Map props(Uri uri, Duration maxAge)
  {
    synchronized (cachedProps)
    {
      CachedProps cp = (CachedProps)cachedProps.get(uri);
      if (cp == null || Duration.nowTicks() - cp.read > maxAge.ticks)
        cp = refreshProps(uri, cp);
      return cp.props;
    }
  }

  private CachedProps refreshProps(Uri uri, CachedProps cp)
  {
    List files = findAllFiles(uri);
    if (cp != null && !cp.isStale(files)) return cp;
    cp = new CachedProps(files);
    cachedProps.put(uri, cp);
    return cp;
  }

  static Map readProps(List files)
  {
    if (files.isEmpty()) return emptyProps;
    Map acc = null;
    for (int i=files.sz()-1; i>=0; --i)
    {
      InStream in = ((File)files.get(i)).in();
      try
      {
        Map props = in.readProps();
        if (acc == null) acc = props;
        else acc.addAll(props);
      }
      finally { in.close(); }
    }
    return acc;
  }

  static class CachedProps
  {
    CachedProps(List files)
    {
      this.files = files;
      this.modified = new long[files.sz()];
      for (int i=0; i<files.sz(); ++i)
        this.modified[i] = ((File)files.get(i)).modified().ticks();
      this.props = (Map)readProps(files).toImmutable();
      this.read = Duration.nowTicks();
    }

    boolean isStale(List x)
    {
      if (files.sz() != x.sz()) return true;
      for (int i=0; i<x.sz(); ++i)
        if (modified[i] != ((File)x.get(i)).modified().ticks())
          return true;
      return false;
    }

    long read;        // Duration.nowTicks when we read
    List files;       // list of files we read from
    long[] modified;  // timestamps of file when we read
    Map props;        // immutable props read
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Map emptyProps = (Map)new Map(new MapType(Sys.StrType, Sys.StrType)).toImmutable();

  private Env parent;
  private HashMap cachedProps = new HashMap();
}