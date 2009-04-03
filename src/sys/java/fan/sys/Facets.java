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

  /**
   * This is the constructor used during decoding the pod
   * file. The values are all passed in as encoded Strings.
   */
  public static Facets make(HashMap src)
  {
    if (src == null || src.size() == 0) return empty();
    return new Facets(src);
  }

  /**
   * Create from map.
   */
  public static Facets make(Map map)
  {
    if (map == null || map.isEmpty()) return empty();

    HashMap src = new HashMap();
    Iterator it = map.pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      String key = (String)e.getKey();
      Object val = e.getValue();
      if (FanObj.isImmutable(val))
        src.put(key, toValue(val));
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

  final synchronized Object get(String name, Object def)
  {
    Object val = src.get(name);
    if (val == null) return def;

    // if we've already decoded, go with it
    if (!(val instanceof String)) return fromValue(val);

    // decode into an object
    Object obj = ObjDecoder.decode((String)val);

    // if the object is immutable, then it
    // safe to reuse for future gets
    Object x = toImmutable(obj);
    if (x == null) return obj;
    src.put(name, toValue(x));
    return x;
  }

  private static Object toImmutable(Object obj)
  {
    if (FanObj.isImmutable(obj)) return obj;

    if (obj instanceof List)
    {
      List list = (List)obj;
      if (list.of().isConst())
        return list.toImmutable();
    }

    if (obj instanceof Map)
    {
      Map map = (Map)obj;
      MapType mapType = (MapType)map.type();
      if (mapType.k.isConst() && mapType.v.isConst())
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
      String name = (String)it.next();
      Object val = get(name, null);
      map.set(name, val);
      allImmutable &= FanObj.isImmutable(val);
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

  private static Object toValue(Object obj)
  {
    // we can't store a String as a value in the map b/c that
    // is how we store the values which are still encoded
    if (obj instanceof String)
      return new StrVal((String)obj);
    else
      return obj;
  }

  private static Object fromValue(Object obj)
  {
    if (obj instanceof StrVal)
      return ((StrVal)obj).val;
    else
      return obj;
  }

  static class StrVal
  {
    StrVal(String val) { this.val = val; }
    public String toString() { return val; }
    String val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static MapType mapType;
  private static Facets empty;

  private HashMap src;     // String -> String or immutable Obj
  private Map immutable;   // immutable Str:Object Fan map

}