//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Creation
//   22 Jul 09  Brian Frank  Port to C#
//

using System;
using System.Collections;
using FileSystemInfo = System.IO.FileSystemInfo;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Repo: TODO
  /// </summary>
  public sealed class Repo : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Find
  //////////////////////////////////////////////////////////////////////////

    public static Repo working() { return m_working; }

    public static Repo boot() { return m_boot; }

    public static List list() { return m_list; }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructor
  //////////////////////////////////////////////////////////////////////////

    private Repo(string n, File h) { m_name = n; m_home = h; }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string name() { return m_name; }

    public override long hash()  { return Sys.idHash(this); }

    public override int GetHashCode() { return (int)Sys.idHash(this); }

    public override bool Equals(Object that)  { return this == that; }

    public override string toStr()  { return m_name + " [" + m_home + "]";  }

    public override Type @typeof()  { return null;  }

  //////////////////////////////////////////////////////////////////////////
  // Files
  //////////////////////////////////////////////////////////////////////////

    public File home() { return m_home; }
    public FileSystemInfo homeDotnet() { return ((LocalFile)m_home).m_file; }

    public static File findFile(string uri) { return findFile(Uri.fromStr(uri), true); }
    public static File findFile(string uri, bool check) { return findFile(Uri.fromStr(uri), check); }
    public static File findFile(Uri uri) { return findFile(uri, true); }
    public static File findFile(Uri uri, bool check)
    {
      if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri).val;
      for (int i=0; i<m_list.size(); ++i)
      {
        Repo repo = (Repo)m_list.get(i);
        File file = repo.m_home.plus(uri, false);
        if (file.exists()) return file;
      }
      if (!check) return null;
      throw IOErr.make("Repo file not found: " + uri).val;
    }

    public static List findAllFiles(Uri uri)
    {
      if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri).val;
      List acc = new List(Sys.FileType);
      for (int i=0; i<m_list.size(); ++i)
      {
        Repo repo = (Repo)m_list.get(i);
        File file = repo.m_home.plus(uri, false);
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
    internal static PodFile findPod(string name)
    {
      Uri uri = Uri.fromStr("lib/fan/" + name + ".pod");
      for (int i=0; i<m_list.size(); ++i)
      {
        Repo repo = (Repo)m_list.get(i);
        File file = repo.m_home.plus(uri, false);
        if (file.exists())
        {
          PodFile r = new PodFile();
          r.m_file = ((LocalFile)file).m_file;
          r.m_repo = repo;
          return r;
        }
      }
      return null;
    }
    internal class PodFile { public FileSystemInfo m_file; public Repo m_repo; }

    /**
     * Get all pods as map of 'name:Local'
     */
    internal static Hashtable findAllPods()
    {
      Hashtable acc = new Hashtable();
      for (int i=0; i<m_list.sz(); ++i)
      {
        List files = ((Repo)m_list.get(i)).m_home.plus("lib/fan/").listFiles();
        for (int j=0; j<files.sz(); ++j)
        {
          LocalFile f = (LocalFile)files.get(j);
          string n = f.name();
          if (!n.EndsWith(".pod")) continue;
          n = n.Substring(0, n.Length-".pod".Length);
          if (acc[n] == null) acc[n] = f.m_file;
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
      if (emptySymbols == null)
        emptySymbols = (Map)new Map(new MapType(Sys.StrType, Sys.ObjType.toNullable())).toImmutable();
      return emptySymbols;
    }

    public static Map readSymbolsCached(Uri uri) { return readSymbolsCached(uri, Duration.m_oneMin); }
    public static Map readSymbolsCached(Uri uri, Duration maxAge)
    {
      lock (cachedSymbols)
      {
        CachedSymbols cs = (CachedSymbols)cachedSymbols[uri];
        if (cs == null || Duration.nowTicks() - cs.m_read > maxAge.m_ticks)
          cs = refreshSymbols(uri, cs);
        return cs.m_symbols;
      }
    }

    private static CachedSymbols refreshSymbols(Uri uri, CachedSymbols cs)
    {
      List files = findAllFiles(uri);
      if (cs != null && !cs.isStale(files)) return cs;
      cs = new CachedSymbols(files);
      cachedSymbols[uri] = cs;
      return cs;
    }

    class CachedSymbols
    {
      internal CachedSymbols(List files)
      {
        m_files = files;
        m_modified = new long[files.sz()];
        for (int i=0; i<files.sz(); ++i)
          m_modified[i] = ((File)files.get(i)).modified().ticks();
        m_symbols = (Map)readSymbols(files).toImmutable();
        m_read = Duration.nowTicks();
      }

      internal bool isStale(List x)
      {
        if (m_files.sz() != x.sz()) return true;
        for (int i=0; i<x.sz(); ++i)
        {
          if (m_modified[i] != ((File)x.get(i)).modified().ticks())
            return true;
        }
        return false;
      }

      internal long m_read;        // Duration.nowTicks when we read
      internal List m_files;       // list of files we read from
      internal long[] m_modified;  // timestamps of file when we read
      internal Map m_symbols;      // immutable symbols read
    }

  //////////////////////////////////////////////////////////////////////////
  // Boostrap
  //////////////////////////////////////////////////////////////////////////

    static readonly Repo m_working;
    static readonly Repo m_boot;
    static readonly List m_list;
    static Hashtable cachedSymbols = new Hashtable();
    static Map emptySymbols;

    static Repo()
    {
      Repo b = null, w = null;
      List a = null;
      try
      {
        // boot repo
        b = new Repo("boot", Sys.m_homeDir.normalize());

        // working repo
        File wd = resolveWorking();
        if (wd != null) w = new Repo("working", wd);
        else w = b;

        // list of all repos
        Repo[] array = (b == w) ? new Repo[] { b } : new Repo[] { w, b };
        a = (List)new List(Sys.ObjType, array).toImmutable();
      }
      catch (Exception e) { Err.dumpStack(e); }

      // assign to static fields exactly once to please javac
      m_working = w;
      m_boot = b;
      m_list = a;
    }

    static File resolveWorking()
    {
      string env = Environment.GetEnvironmentVariable("FAN_REPO");
      if (env == null) return null;
      try
      {
        File f = File.os(env).normalize();
        if (!f.exists()) f = File.make(Uri.fromStr(env).plusSlash(), false).normalize();
        if (!f.isDir()) throw new Exception("Repo must be dir: " + f);
        return f;
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: cannot resolve working dir: " + env);
        Err.dumpStack(e);
        return null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    readonly string m_name;
    readonly File m_home;

  }
}