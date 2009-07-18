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
import fanx.serial.*;

/**
 * Facets manages facet meta-data as a Str:Obj map.
 */
public final class Facets
{

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
      if (emptyMap == null) emptyMap = new Map(mapType()).toImmutable();
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

  /** String qname => immutable Obj or Symbol.EncodedVal */
  private HashMap map;

}