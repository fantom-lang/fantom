//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Original Repo code
//   28 Jan 10  Brian Frank  Split out into Env helper class
//

using System.Collections;
using System.Runtime.CompilerServices;
using Fan.Sys;

namespace Fanx.Util
{
  public class EnvProps
  {
    public EnvProps(Env env) { this.m_env = env; }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Map get(Pod pod, Uri uri, Duration maxAge)
    {
      Key key = new Key(pod, uri);
      CachedProps cp = (CachedProps)m_cache[key];
      if (cp == null || Duration.nowTicks() - cp.m_read > maxAge.m_ticks)
        cp = refresh(key, cp);
      return cp.m_props;
    }

    private CachedProps refresh(Key key, CachedProps cp)
    {
      List files = m_env.findAllFiles(Uri.fromStr("etc/" + key.m_pod + "/" + key.m_uri));
      if (cp != null && !cp.isStale(files)) return cp;
      if (key.m_uri.isPathAbs()) throw ArgErr.make("Env.props Uri must be relative: " + key.m_uri).val;
      cp = new CachedProps(key, files);
      m_cache[key] = cp;
      return cp;
    }

    static Map readDef(Pod pod, Uri uri)
    {
      uri = Uri.fromStr(pod.uri() + "/" + uri);
      Fan.Sys.File f = (Fan.Sys.File)pod.file(uri, false);
      Map map = Sys.m_emptyStrStrMap;
      try
      {
        if (f != null) map = (Map)f.readProps().toImmutable();
      }
      catch (System.Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot load props " + pod + "::" + uri);
        System.Console.WriteLine("  " + e);
      }
      return map;
    }

    static Map read(Map defProps, Key key, List files)
    {
      if (files.isEmpty()) return defProps;
      Map acc = defProps.dup();
      for (int i=files.sz()-1; i>=0; --i)
      {
        InStream input = ((File)files.get(i)).@in();
        try { acc.setAll(input.readProps()); }
        finally { input.close(); }
      }
      return (Map)acc.toImmutable();
    }

  //////////////////////////////////////////////////////////////////////////
  // Key
  //////////////////////////////////////////////////////////////////////////

    class Key
    {
      public Key(Pod p, Uri u) { m_pod = p; m_uri = u; }
      public override int GetHashCode() { return m_pod.GetHashCode() ^ m_uri.GetHashCode(); }
      public override bool Equals(object o) { Key x = (Key)o; return m_pod == x.m_pod && m_uri == x.m_uri; }
      public Pod m_pod;
      public Uri m_uri;
    }

  //////////////////////////////////////////////////////////////////////////
  // CachedProps
  //////////////////////////////////////////////////////////////////////////

    class CachedProps
    {
      public CachedProps(Key key, List files)
      {
        this.m_files = files;
        this.m_modified = new long[files.sz()];
        for (int i=0; i<files.sz(); ++i)
          this.m_modified[i] = ((File)files.get(i)).modified().ticks();
        this.m_defProps = readDef(key.m_pod, key.m_uri);
        this.m_props = read(m_defProps, key, files);
        this.m_read = Duration.nowTicks();
      }

      public bool isStale(List x)
      {
        if (m_files.sz() != x.sz()) return true;
        for (int i=0; i<x.sz(); ++i)
          if (m_modified[i] != ((File)x.get(i)).modified().ticks())
            return true;
        return false;
      }

      public long m_read;        // Duration.nowTicks when we read
      public List m_files;       // list of files we read from
      public long[] m_modified;  // timestamps of file when we read
      public Map m_defProps;     // props defined in pod resource (immutable)
      public Map m_props;        // immutable props read
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

     private Env m_env;
     private Hashtable m_cache = new Hashtable();
  }
}