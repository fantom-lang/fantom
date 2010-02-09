//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 08  Andy Frank  Creation
//

using System.Collections;
using System.Text;
using Fan.Sys;

namespace Fanx.Util
{
  /// <summary>
  /// ScriptUtil manages script caching and compilation.
  /// </summary>
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
      if (!getOption(options, m_strForce, false))
      {
        CachedScript c = getCache(file);

        // if cached, try to lookup type (it might have been GCed)
        if (c != null)
        {
          Type t1 = Type.find(c.typeName, false);
          if (t1 != null) return t1;
        }
      }

      // generate a unique pod name
      string podName = generatePodName(file);

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
        throw Err.make("Script file defines no public classes: " +  file).val;

      // put it into the cache
      putCache(file, t);

      return t;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    private string generatePodName(File f)
    {
      string bse = f.basename();
      StringBuilder s = new StringBuilder(bse.Length+6);
      for (int i=0; i<bse.Length; ++i)
      {
        int c = bse[i];
        if ('a' <= c && c <= 'z') { s.Append((char)c); continue; }
        if ('A' <= c && c <= 'Z') { s.Append((char)c); continue; }
        if (i > 0 && '0' <= c && c <= '9') { s.Append((char)c); continue; }
      }
      lock (m_counterLock) { s.Append('_').Append(m_counter++); }
      return s.ToString();
    }

    private Pod compile(string podName, File f, Map options)
    {
      // use Fantom reflection to run compiler::Main.compileScript(File)
      Method m = Slot.findMethod("compiler::Main.compileScript", true);
      return (Pod)m.call(podName, f, options);
    }

  //////////////////////////////////////////////////////////////////////////
  // CachedScript
  //////////////////////////////////////////////////////////////////////////

    CachedScript getCache(File file)
    {
      lock (m_cache)
      {
        // check cache
        string key = cacheKey(file);
        CachedScript c = (CachedScript)m_cache[key];
        if (c == null) return null;

        // check that timestamp and size still the same
        if (OpUtil.compareEQ(c.modified, file.modified()) &&
            OpUtil.compareEQ(c.size, file.size()))
          return c;

        // nuke from cache
        m_cache.Remove(key);
        return null;
      }
    }

    void putCache(File file, Type t)
    {
      CachedScript c = new CachedScript();
      c.modified = file.modified();
      c.size     = file.size();
      c.typeName = t.qname();

      lock (m_cache) { m_cache[cacheKey(file)] = c; }
    }

    string cacheKey(File f)
    {
      return f.toStr();
    }

    class CachedScript
    {
      public DateTime modified;
      public Long size;
      public string typeName;
    }

  //////////////////////////////////////////////////////////////////////////
  // Option Utils
  //////////////////////////////////////////////////////////////////////////

    bool getOption(Map options, string key, bool def)
    {
      if (options == null) return def;
      Boolean x = (Boolean)options.get(key);
      if (x == null) return def;
      return x.booleanValue();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Hashtable m_cache = new Hashtable(300);
    string m_strForce = "force";
    object m_counterLock = new object();
    int m_counter = 0;

  }
}