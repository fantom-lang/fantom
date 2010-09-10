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
  public static Facets empty()
  {
    Facets e = empty;
    if (e != null) return e;
    return empty = new Facets(new HashMap());
  }

  static Facets mapFacets(Pod pod, FAttrs.FFacet[] ffacets)
  {
    if (ffacets == null || ffacets.length == 0) return empty();
    HashMap map = new HashMap(ffacets.length*3);
    for (int i=0; i<ffacets.length; ++i)
    {
      FAttrs.FFacet ff = ffacets[i];
      Type t = pod.type(ff.type);
      if (!t.isJava()) map.put(t, ff.val);
    }
    return new Facets(map);
  }

  Facets(HashMap map) { this.map = map; }

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

  private static Facets empty;

  private HashMap map;   // Type : String/Facet, lazy decoding
  private List list;     // Facet[]

}