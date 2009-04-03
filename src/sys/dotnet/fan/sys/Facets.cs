//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//   4 Sep 07   Andy Frank  Rework for new design
//

using System.Collections;
using System.Runtime.CompilerServices;
using Fanx.Fcode;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Facets manages facet meta-data as a string:Obj map.
  /// </summary>
  public sealed class Facets
  {

  //////////////////////////////////////////////////////////////////////////
  // FCode
  //////////////////////////////////////////////////////////////////////////

    public static MapType mapType()
    {
      MapType t = m_mapType;
      if (t != null) return t;
      return m_mapType = new MapType(Sys.StrType, Sys.ObjType);
    }

    public static Facets empty()
    {
      Facets e = m_empty;
      if (e != null) return e;
      return m_empty = new Facets(new Hashtable());
    }

    /// <summary>
    /// This is the constructor used during decoding the pod
    /// file. The values are all passed in as encoded Strings.
    /// </summary>
    public static Facets make(Hashtable src)
    {
      if (src == null || src.Count == 0) return empty();
      return new Facets(src);

    }

    /// <summary>
    /// Create from map.
    /// </summary>
    public static Facets make(Map map)
    {
      if (map == null || map.isEmpty()) return empty();

      Hashtable src = new Hashtable();
      IDictionaryEnumerator en = map.pairsIterator();
      while (en.MoveNext())
      {
        string key = (string)en.Key;
        object val = en.Value;
        if (FanObj.isImmutable(val))
          src[key] = val;
        else
          src[key] = ObjEncoder.encode(val);
      }

      return new Facets(src);
    }

  //////////////////////////////////////////////////////////////////////////
  // Private Constructor
  //////////////////////////////////////////////////////////////////////////

    private Facets(Hashtable src)
    {
      this.m_src = src;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    internal object get(string name, object def)
    {
      object val = m_src[name];
      if (val == null) return def;

      // if we've already decoded, go with it
      if (!(val is string)) return fromValue(val);

      // decode into an object
      object obj = ObjDecoder.decode((string)val);

      // if the object is immutable, then it
      // safe to reuse for future gets
      object x = toImmutable(obj);
      if (x == null) return obj;
      m_src[name] = toValue(x);
      return x;
    }

    private object toImmutable(object obj)
    {
      if (FanObj.isImmutable(obj)) return obj;

      if (obj is List)
      {
        List list = (List)obj;
        if (list.of().isConst())
          return list.toImmutable();
      }

      if (obj is Map)
      {
        Map map = (Map)obj;
        MapType mapType = (MapType)map.type();
        if (mapType.m_k.isConst() && mapType.m_v.isConst())
          return map.toImmutable();
      }

      return null;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    internal Map map()
    {
      // if we've previously determined the whole
      // map is immutable then go with it!
      Map x = this.m_immutable;
      if (x != null) return x;

      // map the names to Objs via the get() where
      // we will decode as necessary; keep track if
      // all the values are immutable
      Map map = new Map(mapType());

      // we can't modify the Hashtable while enumerating an
      // Enumeration, so we need to create a disconnected
      // copy of our keys to modify.
      bool allImmutable = true;
      string[] keys = new string[m_src.Count];
      m_src.Keys.CopyTo(keys, 0);
      foreach (string name in keys)
      {
        object val = get(name, null);
        map.set(name, val);
        allImmutable &= FanObj.isImmutable(val);
      }

      // if all the values were immutable, then we
      // can create a reusable immutable map for
      // all future calls
      if (allImmutable)
        return this.m_immutable = map.toImmutable();
      else
        return map.ro();
    }

    public override string ToString()
    {
      return map().ToString();
    }

    private static object toValue(object obj)
    {
      // we can't store a String as a value in the map b/c that
      // is how we store the values which are still encoded
      if (obj is string)
        return new StrVal((string)obj);
      else
        return obj;
    }

    private static object fromValue(object obj)
    {
      if (obj is StrVal)
        return ((StrVal)obj).val;
      else
        return obj;
    }

    internal class StrVal
    {
      internal StrVal(string val) { this.val = val; }
      public string toString() { return val; }
      internal string val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static MapType m_mapType;
    private static Facets m_empty;

    private Hashtable m_src;   // string -> string or immutable Obj
    private Map m_immutable;   // immutable string:Obj Fan map

  }
}