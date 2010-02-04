//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jul 06  Brian Frank  Creation
//   4 Sep 07  Brian Frank  Rework for new design
//
package fan.sys;

import java.util.Iterator;
import java.util.HashMap;
import java.util.Map.Entry;
import fanx.fcode.*;
import fanx.serial.*;

/**
 * Facets manages facet meta-data as a Str:Obj map.
 */
public final class Facets
{

  static Facets mapFacets(Pod pod, FAttrs.FFacet[] ffacets)
  {
    if (ffacets == null || ffacets.length == 0) return empty();
    HashMap map = new HashMap(ffacets.length*3);
    for (int i=0; i<ffacets.length; ++i)
    {
      FAttrs.FFacet ff = ffacets[i];
      Type t = pod.type(ff.type);
      map.put(t, ff.val);
    }
    return new Facets(map);
  }

  final synchronized List list()
  {
    if (list == null)
    {
      list = new List(Sys.FacetType, map.size());
      Iterator it = map.keySet().iterator();
      while (it.hasNext())
      {
        Type type = (Type)it.next();
        list.add(get(type, true));
      }
      list = (List)list.toImmutable();
    }
    return list;
  }

  final synchronized Facet get(Type type, boolean checked)
  {
    Object val = map.get(type);
    if (val instanceof Facet) return (Facet)val;
    if (val instanceof String)
    {
      Facet f = decode(type, (String)val);
      map.put(type, f);
      return f;
    }
    if (checked) throw UnknownFacetErr.make(type.qname()).val;
    return null;
  }

  final Facet decode(Type type, String s)
  {
    try
    {
      // if no string use make/defVal
      if (s.length() == 0) return (Facet)type.make();

      // decode using normal Fantom serialization
      return (Facet)ObjDecoder.decode(s);
    }
    catch (Throwable e)
    {
      String msg = "ERROR: Cannot decode facet " + type + ": " + s;
      System.out.println(msg);
      e.printStackTrace();
      map.remove(type);
      throw IOErr.make(msg).val;
    }
  }


// TODO-FACETS: all the old shit

//////////////////////////////////////////////////////////////////////////
// FCode
//////////////////////////////////////////////////////////////////////////

  public static MapType mapType()
  {
    MapType t = mapType;
    if (t != null) return t;
    return mapType = new MapType(Sys.SymbolType, Sys.ObjType.toNullable());
  }

  public static Facets empty()
  {
    Facets e = empty;
    if (e != null) return e;
    return empty = new Facets(new HashMap());
  }

  /**
   * This is the constructor used during decoding the pod
   * file.  String qname keys and either decoded Objects
   * or Symbol.EncodedVals.
   */
  public static Facets make(HashMap src)
  {
    if (src == null || src.size() == 0) return empty();
    return new Facets(src);
  }

//////////////////////////////////////////////////////////////////////////
// Private Constructor
//////////////////////////////////////////////////////////////////////////

  private Facets(HashMap map) { this.map = map ; }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  final Object get(Symbol key, Object def) { return get(key.qname, def); }

  final synchronized Object get(String qname, Object def)
  {
    Object val = map.get(qname);
    if (val == null) return def;

    // if we've already decoded, go with it
    if (!(val instanceof Symbol.EncodedVal)) return val;

    // decode into an object
    Object obj = Symbol.decodeVal((Symbol.EncodedVal)val);

    // if the object is immutable, then it safe to cache
    if (FanObj.isImmutable(obj)) map.put(qname, obj);

    return obj;
  }

  final synchronized Map map()
  {
    // optimize empty case which is the common case
    if (map.size() == 0)
    {
      if (emptyMap == null) emptyMap = (Map)new Map(mapType()).toImmutable();
      return emptyMap;
    }

    // map the names to Objs via the get() where
    // we will decode as necessary; keep track if
    // all the values are immutable
    Map result = new Map(mapType());
    Iterator it = map.keySet().iterator();
    while (it.hasNext())
    {
      String qname = (String)it.next();
      Symbol key = Symbol.find(qname);
      Object val = get(qname, null);
      result.set(key, val);
    }
    return result.ro();
  }

  public String toString() { return map().toString(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static MapType mapType;
  private static Facets empty;
  private static Map emptyMap;

  private HashMap map;   // Type : String/Facet, lazy decoding
  private List list;     // Facet[]

}