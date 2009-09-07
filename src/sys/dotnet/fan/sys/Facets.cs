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
      return m_mapType = new MapType(Sys.SymbolType, Sys.ObjType.toNullable());
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

  //////////////////////////////////////////////////////////////////////////
  // Private Constructor
  //////////////////////////////////////////////////////////////////////////

    private Facets(Hashtable map) { this.m_map = map; }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public object get(Symbol key, object def)
    {
      return get(key.qname(), def);
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public object get(string qname, object def)
    {
      object val = m_map[qname];
      if (val == null) return def;

      // if we've already decoded, go with it
      if (!(val is Symbol.EncodedVal)) return val;

      // decode into an object
      object obj = Symbol.decodeVal((Symbol.EncodedVal)val);

      // if the object is immutable, then it safe to cache
      if (FanObj.isImmutable(obj)) m_map[qname] = obj;

      return obj;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Map map()
    {
      // optimize empty case which is the common case
      if (m_map.Count == 0)
      {
        if (m_emptyMap == null) m_emptyMap = (Map)new Map(mapType()).toImmutable();
        return m_emptyMap;
      }

      // map the names to Objs via the get() where
      // we will decode as necessary; keep track if
      // all the values are immutable
      Map result = new Map(mapType());
      string[] keys = new string[m_map.Count];
      m_map.Keys.CopyTo(keys, 0);
      foreach (string qname in keys)
      {
        Symbol key = Symbol.find(qname);
        object val = get(qname, null);
        result.set(key, val);
      }
      return result.ro();
    }

    public override string ToString()
    {
      return map().ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static MapType m_mapType;
    private static Facets m_empty;
    private static Map m_emptyMap;

    /** String qname => immutable Obj or Symbol.EncodedVal */
    private Hashtable m_map;
  }
}

