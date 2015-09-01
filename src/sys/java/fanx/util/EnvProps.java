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
  public EnvProps(Env env)
  {
    this.env = env;
  }

  public synchronized void reload()
  {
    this.cache.clear();
    this.envPropPods = null;
  }

  public Map get(Pod pod, Uri uri, Duration maxAge)
  {
    // lazy load pods with sys.envProps index prop (not for config.props)
    Pod[] otherPods = null;
    if (!uri.name().equals("config.props"))
    {
      if (envPropPods == null) envPropPods = loadEnvPropPods();
      otherPods = envPropPods;
    }

    // lookup cached props for key (refresh if not found or expired)
    synchronized(this)
    {
      Key key = new Key(pod.name(), uri);
      CachedProps cp = (CachedProps)cache.get(key);
      if (cp == null || cp.isExpired(maxAge))
        cp = refresh(pod, key, cp, otherPods);
      return cp.props;
    }
  }

  private Pod[] loadEnvPropPods()
  {
    try
    {
      List podNames = env.index("sys.envProps");
      Pod[] pods = new Pod[podNames.sz()];
      for (int i=0; i<pods.length; ++i)
        pods[i] = Pod.find((String)podNames.get(i), true);

      if (System.getenv("FAN_DEBUG_ENVPROPS") != null)
      {
        String s = "EnvProps.loadEnvPropPods (" + pods.length + ")";
        for (int i=0; i<pods.length; ++i) s = s + (i == 0 ? ": " : ", ") + pods[i];
        System.out.println(s);
      }

      return pods;
    }
    catch (Throwable e) { e.printStackTrace(); }
    return new Pod[0];
  }

  private CachedProps refresh(Pod pod, Key key, CachedProps cp, Pod[] otherPods)
  {
    List files = env.findAllFiles(Uri.fromStr("etc/" + key.pod + "/" + key.uri));
    if (cp != null && !cp.isStale(files)) return cp;
    if (key.uri.isPathAbs()) throw ArgErr.make("Env.props Uri must be relative: " + key.uri);
    Map defProps = cp != null ? cp.defProps : readDef(pod, key.uri, otherPods);
    cp = new CachedProps(key, defProps, files);
    cache.put(key, cp);
    return cp;
  }

  private static Map readDef(Pod pod, Uri uri, Pod[] otherPods)
  {
    Map map = readPodProps(pod, Uri.fromStr("/" + uri.toStr()));
    if (otherPods != null)
    {
      Uri otherPodUri = Uri.fromStr("/" + pod.name() + "/" + uri.toStr());
      for (int i=0; i<otherPods.length; ++i)
      {
        Map more = readPodProps(otherPods[i], otherPodUri);
        if (!more.isEmpty())
        {
          if (map.isRO()) map = map.dup();
          map.setAll(more);
        }
      }
    }
    return (Map)map.toImmutable();
  }

  private static Map readPodProps(Pod pod, Uri uri)
  {
    fan.sys.File f = (fan.sys.File)pod.file(uri, false);
    try
    {
      if (f != null) return f.readProps();
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot load props " + pod + "::" + uri);
      System.out.println("  " + e);
    }
    return Sys.emptyStrStrMap;
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
    Key(String p, Uri u) { pod = p; uri = u; }
    public int hashCode() { return pod.hashCode() ^ uri.hashCode(); }
    public boolean equals(Object o) { Key x = (Key)o; return pod.equals(x.pod) && uri.equals(x.uri); }
    public String toString() { return "" + pod + ":" + uri; }
    final String pod;
    final Uri uri;
  }

//////////////////////////////////////////////////////////////////////////
// CachedProps
//////////////////////////////////////////////////////////////////////////

  static class CachedProps
  {
    static int count = 0;

    CachedProps(Key key, Map defProps, List files)
    {
      this.files = files;
      this.defProps = defProps;
      this.modified = new long[files.sz()];
      for (int i=0; i<files.sz(); ++i)
        this.modified[i] = ((File)files.get(i)).modified().ticks();
      this.props = read(defProps, key, files);
      this.read = Duration.nowTicks();
    }

    boolean isExpired(Duration maxAge)
    {
      if (maxAge == Duration.maxVal) return false;
      return Duration.nowTicks() - this.read > maxAge.ticks;
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
  private Pod[] envPropPods;
}