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
    return mapType = new MapType(Sys.StrType, Sys.ObjType);
  }

  public static Facets empty()
  {
    Facets e = empty;
    if (e != null) return e;
    return empty = new Facets(new HashMap());
  }

  public static Facets make(HashMap src)
  {
    if (src == null || src.size() == 0) return empty();
    return new Facets(src);
  }

  public static Facets make(Map map)
  {
    if (map == null || map.isEmpty().val) return empty();

    HashMap src = new HashMap();
    Iterator it = map.pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Str key = (Str)e.getKey();
      Object val = e.getValue();
      if (FanObj.isImmutable(val).val)
        src.put(key, val);
      else
        src.put(key, ObjEncoder.encode(val));
    }

    return new Facets(src);
  }

//////////////////////////////////////////////////////////////////////////
// Private Constructor
//////////////////////////////////////////////////////////////////////////

  private Facets(HashMap src)
  {
    this.src = src;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  final synchronized Object get(Str name, Object def)
  {
    Object val = src.get(name);
    if (val == null) return def;

    // if we've already decoded, go with it
    if (!(val instanceof String)) return val;

    // decode into an object
    Object obj = ObjDecoder.decode((String)val);

    // if the object is immutable, then it
    // safe to reuse for future gets
    Object x = toImmutable(obj);
    if (x == null) return obj;
    src.put(name, x);
    return x;
  }

  private Object toImmutable(Object obj)
  {
    if (FanObj.isImmutable(obj).val) return obj;

    if (obj instanceof List)
    {
      List list = (List)obj;
      if (list.of().isConst().val)
        return list.toImmutable();
    }

    if (obj instanceof Map)
    {
      Map map = (Map)obj;
      MapType mapType = (MapType)map.type();
      if (mapType.k.isConst().val && mapType.v.isConst().val)
        return map.toImmutable();
    }

    return null;
  }

  final synchronized Map map()
  {
    // if we've previously determined the whole
    // map is immutable then go with it!
    Map x = this.immutable;
    if (x != null) return x;

    // map the names to Objs via the get() where
    // we will decode as necessary; keep track if
    // all the values are immutable
    Map map = new Map(mapType());
    Iterator it = src.keySet().iterator();
    boolean allImmutable = true;
    while (it.hasNext())
    {
      Str name = (Str)it.next();
      Object val = get(name, null);
      map.set(name, val);
      allImmutable &= FanObj.isImmutable(val).val;
    }

    // if all the values were immutable, then we
    // can create a reusable immutable map for
    // all future calls
    if (allImmutable)
      return this.immutable = map.toImmutable();
    else
      return map.ro();
  }

  public String toString()
  {
    return map().toString();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static MapType mapType;
  private static Facets empty;

  private HashMap src;     // Str -> String or immutable Obj
  private Map immutable;   // immutable Str:Object Fan map

}