//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;
import fanx.serial.ObjDecoder;

/**
 * Repo
 */
public final class Repo
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  public static Repo working() { return working; }

  public static Repo boot() { return boot; }

  public static List list() { return list; }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  private Repo(String n, File h) { name = n; home = h; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String name() { return name; }

  public long hash()  { return System.identityHashCode(this); }

  public boolean equals(Object that)  { return this == that; }

  public String toStr()  { return name + " [" + home + "]";  }

  public Type type()  { return Sys.RepoType;  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  public File home() { return home; }
  public java.io.File homeJava() { return ((LocalFile)home).file; }

  public static File findFile(String uri) { return findFile(Uri.fromStr(uri), true); }
  public static File findFile(String uri, boolean checked) { return findFile(Uri.fromStr(uri), checked); }
  public static File findFile(Uri uri) { return findFile(uri, true); }
  public static File findFile(Uri uri, boolean checked)
  {
    if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri).val;
    for (int i=0; i<list.size(); ++i)
    {
      Repo repo = (Repo)list.get(i);
      File file = repo.home.plus(uri, false);
      if (file.exists()) return file;
    }
    if (!checked) return null;
    throw IOErr.make("Repo file not found: " + uri).val;
  }

  public static List findAllFiles(Uri uri)
  {
    if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri).val;
    List acc = new List(Sys.FileType);
    for (int i=0; i<list.size(); ++i)
    {
      Repo repo = (Repo)list.get(i);
      File file = repo.home.plus(uri, false);
      if (file.exists()) acc.add(file);
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Pods
//////////////////////////////////////////////////////////////////////////

  /**
   * Find a pod by name in repo or return null
   */
  public static PodFile findPod(String name)
  {
    Uri uri = Uri.fromStr("lib/fan/" + name + ".pod");
    for (int i=0; i<list.size(); ++i)
    {
      Repo repo = (Repo)list.get(i);
      File file = repo.home.plus(uri, false);
      if (file.exists())
      {
        PodFile r = new PodFile();
        r.file = ((LocalFile)file).file;
        r.repo = repo;
        return r;
      }
    }
    return null;
  }
  static class PodFile { java.io.File file; Repo repo; }

  /**
   * Get all pods as map of 'name:java.io.File'
   */
  public static HashMap findAllPods()
  {
    HashMap acc = new HashMap();
    for (int i=0; i<list.sz(); ++i)
    {
      List files = ((Repo)list.get(i)).home.plus("lib/fan/").listFiles();
      for (int j=0; j<files.sz(); ++j)
      {
        LocalFile f = (LocalFile)files.get(j);
        String n = f.name();
        if (!n.endsWith(".pod")) continue;
        n = n.substring(0, n.length()-".pod".length());
        if (acc.get(n) == null) acc.put(n, f.file);
      }
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Symbols
//////////////////////////////////////////////////////////////////////////

  public static Map readSymbols(Uri uri) { return readSymbols(findAllFiles(uri)); }
  public static Map readSymbols(List files)
  {
    if (files.isEmpty())
    {
      if (emptySymbols == null)
        emptySymbols = new Map(new MapType(Sys.StrType, Sys.ObjType.toNullable())).toImmutable();
      return emptySymbols;
    }
    Map map = null;
    for (int i=files.sz()-1; i>=0; --i)
    {
      InStream in = ((File)files.get(i)).in();
      try { map = new ObjDecoder(in, null).readSymbols(map); }
      finally { in.close(); }
    }
    return map;
  }

  public static Map readSymbolsCached(Uri uri) { return readSymbolsCached(uri, Duration.oneMin); }
  public static Map readSymbolsCached(Uri uri, Duration maxAge)
  {
    synchronized (cachedSymbols)
    {
      CachedSymbols cs = (CachedSymbols)cachedSymbols.get(uri);
      if (cs == null || Duration.nowTicks() - cs.read > maxAge.ticks)
        cs = refreshSymbols(uri, cs);
      return cs.symbols;
    }
  }

  private static CachedSymbols refreshSymbols(Uri uri, CachedSymbols cs)
  {
    List files = findAllFiles(uri);
    if (cs != null && !cs.isStale(files)) return cs;
    cs = new CachedSymbols(files);
    cachedSymbols.put(uri, cs);
    return cs;
  }

  static class CachedSymbols
  {
    CachedSymbols(List files)
    {
      this.files = files;
      this.modified = new long[files.sz()];
      for (int i=0; i<files.sz(); ++i)
        this.modified[i] = ((File)files.get(i)).modified().ticks();
      this.symbols = readSymbols(files).toImmutable();
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
    Map symbols;      // immutable symbols read
  }

//////////////////////////////////////////////////////////////////////////
// Boostrap
//////////////////////////////////////////////////////////////////////////

  public static final Repo working;
  public static final Repo boot;
  public static final List list;
  static final HashMap cachedSymbols = new HashMap();
  static Map emptySymbols;

  static
  {
    Repo b = null, w = null;
    List a = null;
    try
    {
      // boot repo
      b = new Repo("boot", Sys.homeDir.normalize());

      // working repo
      File wd = resolveWorking();
      if (wd != null) w = new Repo("working", wd);
      else w = b;

      // list of all repos
      Repo[] array = (b == w) ? new Repo[] { b } : new Repo[] { w, b };
      a = new List(Sys.RepoType, array).toImmutable();
    }
    catch (Exception e) { e.printStackTrace(); }

    // assign to static fields exactly once to please javac
    working = w;
    boot = b;
    list = a;
  }

  static File resolveWorking()
  {
    String env = System.getenv("FAN_REPO");
    if (env == null) return null;
    try
    {
      File f = File.os(env).normalize();
      if (!f.exists()) f = File.make(Uri.fromStr(env).plusSlash(), false).normalize();
      if (!f.isDir()) throw new IllegalStateException("Repo must be dir: " + f);
      return f;
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: cannot resolve working dir: " + env);
      e.printStackTrace();
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////


  final String name;
  final File home;

}