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
 * PropsCache manages caching and compilation of 'Env.props'.
 */
public class PropsCache
{
  public PropsCache(Env env) { this.env = env; }

  public synchronized Map get(String uri, Duration maxAge)
  {
    CachedProps cp = (CachedProps)cache.get(uri);
    if (cp == null || Duration.nowTicks() - cp.read > maxAge.ticks)
      cp = refreshProps(Uri.fromStr(uri), cp);
    return cp.props;
  }

  public synchronized Map get(Uri uri, Duration maxAge)
  {
    CachedProps cp = (CachedProps)cache.get(uri.toStr());
    if (cp == null || Duration.nowTicks() - cp.read > maxAge.ticks)
      cp = refreshProps(uri, cp);
    return cp.props;
  }

  private CachedProps refreshProps(Uri uri, CachedProps cp)
  {
    List files = env.findAllFiles(uri);
    if (cp != null && !cp.isStale(files)) return cp;
    cp = new CachedProps(files);
    cache.put(uri.toStr(), cp);
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

  private final Env env;
  private final HashMap cache = new HashMap();
}