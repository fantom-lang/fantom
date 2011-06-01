//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Original Repo code
//   28 Jan 10  Brian Frank  Split out into Env helper class
//
package fanx.util;

import java.util.HashMap;
import fan.sys.*;

/**
 * EnvProps manages caching and compilation of 'Env.props'.
 */
public class EnvProps
{
  public EnvProps(Env env) { this.env = env; }

  public synchronized Map get(Pod pod, Uri uri, Duration maxAge)
  {
    Key key = new Key(pod, uri);
    CachedProps cp = (CachedProps)cache.get(key);
    if (cp == null || Duration.nowTicks() - cp.read > maxAge.ticks)
      cp = refresh(key, cp);
    return cp.props;
  }

  private CachedProps refresh(Key key, CachedProps cp)
  {
    List files = env.findAllFiles(Uri.fromStr("etc/" + key.pod + "/" + key.uri));
    if (cp != null && !cp.isStale(files)) return cp;
    if (key.uri.isPathAbs()) throw ArgErr.make("Env.props Uri must be relative: " + key.uri);
    cp = new CachedProps(key, files);
    cache.put(key, cp);
    return cp;
  }

  static Map readDef(Pod pod, Uri uri)
  {
    uri = Uri.fromStr(pod.uri() + "/" + uri);
    fan.sys.File f = (fan.sys.File)pod.file(uri, false);
    Map map = Sys.emptyStrStrMap;
    try
    {
      if (f != null) map = (Map)f.readProps().toImmutable();
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot load props " + pod + "::" + uri);
      System.out.println("  " + e);
    }
    return map;
  }

  static Map read(Map defProps, Key key, List files)
  {
    if (files.isEmpty()) return defProps;
    Map acc = defProps.dup();
    for (int i=files.sz()-1; i>=0; --i)
    {
      InStream in = ((File)files.get(i)).in();
      try { acc.setAll(in.readProps()); }
      finally { in.close(); }
    }
    return (Map)acc.toImmutable();
  }

//////////////////////////////////////////////////////////////////////////
// Key
//////////////////////////////////////////////////////////////////////////

  static final class Key
  {
    Key(Pod p, Uri u) { pod = p; uri = u; }
    public int hashCode() { return pod.hashCode() ^ uri.hashCode(); }
    public boolean equals(Object o) { Key x = (Key)o; return pod == x.pod && uri.equals(x.uri); }
    final Pod pod;
    final Uri uri;
  }

//////////////////////////////////////////////////////////////////////////
// CachedProps
//////////////////////////////////////////////////////////////////////////

  static class CachedProps
  {
    CachedProps(Key key, List files)
    {
      this.files = files;
      this.modified = new long[files.sz()];
      for (int i=0; i<files.sz(); ++i)
        this.modified[i] = ((File)files.get(i)).modified().ticks();
      this.defProps = readDef(key.pod, key.uri);
      this.props = read(defProps, key, files);
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
    Map defProps;     // props defined in pod resource (immutable)
    Map props;        // immutable props read
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final Env env;
  private final HashMap cache = new HashMap();
}