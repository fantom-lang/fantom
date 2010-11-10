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
    Facets x = emptyVal;
    if (x == null) x = emptyVal = new Facets(new HashMap());
    return x;
  }

  public static Facets makeTransient()
  {
    Facets x = transientVal;
    if (x == null)
    {
      HashMap m = new HashMap();
      m.put(Sys.TransientType, "");
      x = transientVal = new Facets(m);
    }
    return x;
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

  private Facets(HashMap map) { this.map = map; }

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

  final Facets dup()
  {
    return new Facets((HashMap)map.clone());
  }

  final void inherit(Facets facets)
  {
    if (facets.map.size() == 0) return;
    list = null;
    Iterator it = facets.map.entrySet().iterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      Type key = (Type)entry.getKey();

      // if already mapped skipped
      if (map.get(key) != null) continue;

      // if not an inherited facet skip it
      FacetMeta meta = (FacetMeta)key.facet(Sys.FacetMetaType, false);
      if (meta == null || !meta.inherited) continue;

      // inherit
      map.put(key, entry.getValue());
    }
  }

  private static Facets emptyVal;
  private static Facets transientVal;

  private HashMap map;   // Type : String/Facet, lazy decoding
  private List list;     // Facet[]

}