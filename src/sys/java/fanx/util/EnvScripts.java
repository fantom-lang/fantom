//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Mar 08  Brian Frank  Creation
//
package fanx.util;

import java.util.HashMap;
import fan.sys.*;

/**
 * EnvScripts manages caching and compilation of 'Env.compileScript'.
 */
public class EnvScripts
{

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  public Type compile(File file, Map options)
  {
    // normalize the file path as our cache key
    file = file.normalize();

    // unless force=true, check the cache
    if (!getOption(options, "force", false))
    {
      CachedScript c = getCache(file);

      // if cached, try to lookup type (it might have been GCed)
      if (c != null)
      {
        Type t = Type.find(c.typeName, false);
        if (t != null) return t;
      }
    }

    // generate a unique pod name
    String podName = generatePodName(file);

    // compile the script
    Pod pod = compile(podName, file, options);

    // get the primary type
    List types = pod.types();
    Type t = null;
    for (int i=0; i<types.sz(); ++i)
    {
      t = (Type)types.get(i);
      if (t.isPublic()) break;
    }
    if (t == null)
      throw Err.make("Script file defines no public classes: " +  file);

    // put it into the cache
    putCache(file, t);

    return t;
  }

  public String compileJs(File file, Map options)
  {
    // normalize the file path as our cache key
    file = file.normalize();

    // get pod name
    String podName = (String)options.get("podName");
    if (podName == null) podName = generatePodName(file);

    // compile the script
    return compileJs(podName, file, options);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private String generatePodName(File f)
  {
    String base = f.basename();
    StringBuilder s = new StringBuilder(base.length()+6);
    for (int i=0; i<base.length(); ++i)
    {
      int c = base.charAt(i);
      if ('a' <= c && c <= 'z') { s.append((char)c); continue; }
      if ('A' <= c && c <= 'Z') { s.append((char)c); continue; }
      if (i > 0 && '0' <= c && c <= '9') { s.append((char)c); continue; }
    }
    synchronized (counterLock) { s.append('_').append(counter++); }
    return s.toString();
  }

  private Pod compile(String podName, File f, Map options)
  {
    // use Fantom reflection to run compiler::Main.compileScript(File)
    Method m = Slot.findMethod("compiler::Main.compileScript", true);
    return (Pod)m.call(podName, f, options);
  }

  private String compileJs(String podName, File f, Map options)
  {
    // use Fantom reflection to run compiler::Main.compileScriptToJs(File)
    Method m = Slot.findMethod("compiler::Main.compileScriptToJs", true);
    return (String)m.call(podName, f, options);
  }

//////////////////////////////////////////////////////////////////////////
// CachedScript
//////////////////////////////////////////////////////////////////////////

  CachedScript getCache(File file)
  {
    synchronized (cache)
    {
      // check cache
      String key = cacheKey(file);
      CachedScript c = (CachedScript)cache.get(key);
      if (c == null) return null;

      // check that timestamp and size still the same
      if (OpUtil.compareEQ(c.modified, file.modified()) &&
          OpUtil.compareEQ(c.size, file.size()))
        return c;

      // nuke from cache
      cache.remove(key);
      return null;
    }
  }

  void putCache(File file, Type t)
  {
    CachedScript c = new CachedScript();
    c.modified = file.modified();
    c.size     = file.size();
    c.typeName = t.qname();

    synchronized (cache) { cache.put(cacheKey(file), c); }
  }

  String cacheKey(File f)
  {
    return f.toStr();
  }

  static class CachedScript
  {
    DateTime modified;
    long size;
    String typeName;
  }

//////////////////////////////////////////////////////////////////////////
// Option Utils
//////////////////////////////////////////////////////////////////////////

  static boolean getOption(Map options, String key, boolean def)
  {
    if (options == null) return def;
    Boolean x = (Boolean)options.get(key);
    if (x == null) return def;
    return x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  HashMap cache = new HashMap(300);
  Object counterLock = new Object();
  int counter = 0;

}