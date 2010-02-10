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

    public static Facets empty()
    {
      Facets e = m_empty;
      if (e != null) return e;
      return m_empty = new Facets(new Hashtable());
    }

    public static Facets mapFacets(Pod pod, FAttrs.FFacet[] ffacets)
    {
      if (ffacets == null || ffacets.Length == 0) return empty();
      Hashtable map = new Hashtable();
      for (int i=0; i<ffacets.Length; ++i)
      {
        FAttrs.FFacet ff = ffacets[i];
        Type t = pod.findType(ff.type);
        map[t] = ff.val;
      }
      return new Facets(map);
    }

    private Facets(Hashtable map) { this.m_map = map; }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public List list()
    {
      if (m_list == null)
      {
        m_list = new List(Sys.FacetType, m_map.Count);
        IDictionaryEnumerator en = ((Hashtable)m_map.Clone()).GetEnumerator();
        while (en.MoveNext())
        {
          Type type = (Type)en.Key;
          m_list.add(get(type, true));
        }
        m_list = (List)m_list.toImmutable();
      }
      return m_list;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Facet get(Type type, bool check)
    {
      object val = m_map[type];
      if (val is Facet) return (Facet)val;
      if (val is string)
      {
        Facet f = decode(type, (string)val);
        m_map[type] = f;
        return f;
      }
      if (check) throw UnknownFacetErr.make(type.qname()).val;
      return null;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public Facet decode(Type type, string s)
    {
      try
      {
        // if no string use make/defVal
        if (s.Length == 0) return (Facet)type.make();

        // decode using normal Fantom serialization
        return (Facet)ObjDecoder.decode(s);
      }
      catch (System.Exception e)
      {
        string msg = "ERROR: Cannot decode facet " + type + ": " + s;
        System.Console.WriteLine(msg);
        Err.dumpStack(e);
        m_map.Remove(type);
        throw IOErr.make(msg).val;
      }
    }


    private static Facets m_empty;

    private Hashtable m_map;   // Type : String/Facet, lazy decoding
    private List m_list;       // Facet[]

  }

/*

  //////////////////////////////////////////////////////////////////////////
  // FCode
  //////////////////////////////////////////////////////////////////////////

    public static MapType mapType()
    {
      MapType t = m_mapType;
      if (t != null) return t;
//      return m_mapType = new MapType(Sys.SymbolType, Sys.ObjType.toNullable());
return null;
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


    [MethodImpl(MethodImplOptions.Synchronized)]
    public Facet get(Type qname, bool check)
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
    public List list()
    {
      return null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static MapType m_mapType;
    private static Facets m_empty;
    private static Map m_emptyMap;

    private Hashtable m_map;
  }
  */
}

